extends StaticBody3D

## Автомат условий. Таймер раз в CHECK_INTERVAL сек пересчитывает условие
## каждого активного ряда. При изменении — hold(true/false) на action-кнопке.
##
## Ориентация кубиков при снапе:
##   * look_me  — кубик поворачивается лицом к игроку (+90 к текущему Y)
##   * остальные — фиксированная ориентация из SNAP_OFFSETS.
##
## Поворот кубика в руке неважен — после отпускания кубик принимает
## каноничное положение.

const ROWS := 4
const COLS := 9
const X_START := 0.0
const X_STEP := 0.6
const Y_START := 3.0
const Y_STEP := -0.8
const Z := -0.475

## 50 Гц — достаточно для точного попадания N1 в N2 при быстром росте монитора.
const CHECK_INTERVAL := 0.02

## Ориентация после снапа для не-look_me кубиков.
## Cube_Button: +Z спрятан в стену, "лицо" — на -X, чтобы смотреть на игрока
## нужно повернуть на -90°.
const SNAP_OFFSETS := {
	"BUTTON": Vector3(0, -90, 0),
}

var busy_pos_list: Dictionary = {}    # Cube → Vector2i(row, col)
var row_actions: Dictionary = {}      # Row → Array[Button]
var row_active: Dictionary = {}       # Row → bool
var row_last_state: Dictionary = {}   # Row → bool
var row_busy: Dictionary = {}         # Row → bool (идёт анимация ошибки)

var _check_timer: Timer

# ------------------------------------------------------------
# Lifecycle
# ------------------------------------------------------------

func _ready() -> void:
	for row in [$Row1, $Row2, $Row3, $Row4]:
		row_actions[row] = []
		row_active[row] = false
		row_last_state[row] = false
		row_busy[row] = false

	_check_timer = Timer.new()
	_check_timer.wait_time = CHECK_INTERVAL
	_check_timer.autostart = true
	_check_timer.timeout.connect(_tick)
	add_child(_check_timer)

# ------------------------------------------------------------
# Сетка
# ------------------------------------------------------------

static func cell(rc: Vector2i) -> Vector3:
	return Vector3(X_START + rc.y * X_STEP, Y_START + rc.x * Y_STEP, Z)

static func nearest_fast(pos: Vector3) -> Vector2i:
	var c := int(round((pos.x - X_START) / X_STEP))
	var r := int(round((pos.y - Y_START) / Y_STEP))
	if r < 0 or r >= ROWS or c < 0 or c >= COLS:
		return Vector2i(-1, -1)
	return Vector2i(r, c)

## Индекс ряда по позиции Row-узла (+0.6 — Row стоит ниже центра ячейки).
func _row_index(row: Node3D) -> int:
	var local_y := to_local(row.global_position).y + 0.6
	return int(round((local_y - Y_START) / Y_STEP))

func _collect_row_cubes(row: Node3D) -> Array:
	var idx := _row_index(row)
	var pairs: Array = []
	for cube in busy_pos_list:
		var rc: Vector2i = busy_pos_list[cube]
		if rc.x == idx:
			pairs.append([cube, rc.y])
	pairs.sort_custom(func(a, b): return a[1] < b[1])
	return pairs.map(func(p): return p[0])

# ------------------------------------------------------------
# Снап
# ------------------------------------------------------------

func snap(cube: RigidBody3D) -> void:
	if cube not in $Cube_check.get_overlapping_bodies():
		cube.in_automate = false
		busy_pos_list.erase(cube)
		_invalidate_rows()
		return

	var rc := nearest_fast(to_local(cube.global_position))
	if rc.x < 0:
		return

	var old_rc: Vector2i = busy_pos_list.get(cube, Vector2i(-1, -1))
	if old_rc == rc:
		return

	for other in busy_pos_list:
		if other != cube and busy_pos_list[other] == rc:
			_push_away(cube)
			return

	cube.freeze = true
	cube.in_automate = true
	busy_pos_list[cube] = rc

	var angle: Vector3
	if cube.look_me:
		# Лицом к игроку (кубик-монитор, кубик-логика и т.п.)
		angle = cube.rotation_degrees + Vector3(0, 90, 0)
	else:
		# Каноническая ориентация. X/Z выровнены с автоматом,
		# Y — из SNAP_OFFSETS. Игрок не может «сломать» вид кубика,
		# случайно повернув его при броске.
		angle = SNAP_OFFSETS.get(cube.type, Vector3.ZERO)

	var target := to_global(cell(rc))
	var tw := create_tween().set_parallel(true)
	tw.tween_property(cube, "global_position", target, 0.4)
	tw.tween_property(cube, "rotation_degrees", angle, 0.4)

	_invalidate_rows()

func _push_away(cube: RigidBody3D) -> void:
	cube.freeze = false
	cube.in_automate = false
	var forward := global_transform.basis.z.normalized()
	cube.apply_central_impulse(forward * 1.5 + Vector3.UP * 1.5)
	cube.apply_torque_impulse(Vector3(
		randf_range(-2, 2), randf_range(-2, 2), randf_range(-2, 2)))

func _invalidate_rows() -> void:
	for row in row_active.keys():
		if row_active[row]:
			_stop_row(row)

func _on_cube_check_body_entered(cube: Node) -> void:
	if cube.is_in_group("Cube") and not cube.is_drag:
		snap(cube)

func _on_cube_check_body_exited(cube: Node) -> void:
	if not cube.is_in_group("Cube"):
		return
	busy_pos_list.erase(cube)
	_invalidate_rows()

# ------------------------------------------------------------
# Публичный API
# ------------------------------------------------------------

func check_valid(row: Node3D) -> Variant:
	var cubes := _collect_row_cubes(row)
	if cubes.is_empty():
		return -1
	var err := _validate(cubes)
	if err >= 0:
		return err
	return _evaluate(cubes)

# ------------------------------------------------------------
# Запуск / остановка
# ------------------------------------------------------------

func _on_row_play(row: Node3D) -> void:
	if row_busy.get(row, false):
		return
	if row_active.get(row, false):
		_stop_row(row)
	else:
		_start_row(row)

func _start_row(row: Node3D) -> void:
	var cubes := _collect_row_cubes(row)
	if cubes.is_empty():
		row.set_active(false)
		return

	var err := _validate(cubes)
	if err >= 0:
		print("[Automate] %s: ошибка в ячейке %d" % [row.name, err])
		_show_error_animation(row, cubes, err)
		return

	var action := _find_action(cubes)
	if action == null:
		row.set_active(false)
		return

	row_actions[row] = [action]
	row_active[row] = true
	row_last_state[row] = false
	row.set_active(true)
	row.show_running_idle()
	_evaluate_row(row)

	print("[Automate] %s: запущен" % row.name)

func _stop_row(row: Node3D) -> void:
	for btn in row_actions.get(row, []):
		if btn.has_method("hold"):
			btn.hold(false)
	row_actions[row] = []
	row_active[row] = false
	row_last_state[row] = false
	row.set_active(false)
	row.clear_lamps()
	print("[Automate] %s: остановлен" % row.name)

# ------------------------------------------------------------
# Анимация ошибки валидации
# ------------------------------------------------------------

func _show_error_animation(row: Node3D, cubes: Array, err_idx: int) -> void:
	row_busy[row] = true
	row.set_active(false)
	row.clear_lamps()

	# Зелёные по одной до места ошибки
	for i in range(min(err_idx, row.lamp_count())):
		row.set_lamp(i, row.COLOR_GREEN)
		await get_tree().create_timer(0.08).timeout

	# Всё оставшееся (включая ошибочную) — сразу красным
	for i in range(err_idx, row.lamp_count()):
		row.set_lamp(i, row.COLOR_RED)

	await get_tree().create_timer(0.7).timeout
	_eject_row(cubes)
	row.clear_lamps()
	row_busy[row] = false

# ------------------------------------------------------------
# Периодическая проверка
# ------------------------------------------------------------

func _tick() -> void:
	for row in row_active.keys():
		if row_active[row]:
			_evaluate_row(row)

func _evaluate_row(row: Node3D) -> void:
	var cubes := _collect_row_cubes(row)
	if cubes.is_empty():
		_stop_row(row)
		return

	# Кубики могли измениться — перепроверяем валидность
	var err := _validate(cubes)
	if err >= 0:
		print("[Automate] %s: ряд стал невалидным (ячейка %d)" % [row.name, err])
		_stop_row(row)
		_show_error_animation(row, cubes, err)
		return

	var should: bool = not _evaluate(cubes).is_empty()
	var last: bool = row_last_state.get(row, false)
	if should == last:
		return

	row_last_state[row] = should
	for btn in row_actions[row]:
		if btn.has_method("hold"):
			btn.hold(should)

	# Лампочки показывают: действие выполняется (зелёный) или нет (тускло)
	if should:
		row.show_running()
	else:
		row.show_running_idle()

# ------------------------------------------------------------
# Вылет кубиков
# ------------------------------------------------------------

func _eject_row(cubes: Array) -> void:
	var forward := global_transform.basis.z.normalized()
	for cb in cubes:
		busy_pos_list.erase(cb)
		cb.freeze = false
		cb.in_automate = false
		# Строго вперёд + вверх. Без бокового разброса — кубики падают
		# предсказуемой горкой перед автоматом.
		cb.apply_central_impulse(forward * 2.5 + Vector3.UP * 2.0)
		cb.apply_torque_impulse(Vector3(
			randf_range(-2, 2), randf_range(-2, 2), randf_range(-2, 2)))

# ------------------------------------------------------------
# Валидация
# ------------------------------------------------------------

## VALUE ( (COMPARE|LOGIC) VALUE )* DO BUTTON
## NOT — префикс VALUE, допускается цепочка NOT NOT ...
## Несколько DIGIT подряд — одно число, пропускаются как одна единица.
func _validate(cubes: Array) -> int:
	var state := "VALUE"
	var do_count := 0
	var i := 0

	while i < cubes.size():
		var t: String = cubes[i].type
		match state:
			"VALUE":
				match t:
					"MONITOR", "BUTTON":
						state = "OP"
					"DIGIT":
						# Пропускаем всю серию DIGIT как одно число
						while i + 1 < cubes.size() and cubes[i + 1].type == "DIGIT":
							i += 1
						state = "OP"
					"NOT":
						state = "NOT_NEXT"
					_:
						return i
			"NOT_NEXT":
				match t:
					"MONITOR", "BUTTON":
						state = "OP"
					"DIGIT":
						while i + 1 < cubes.size() and cubes[i + 1].type == "DIGIT":
							i += 1
						state = "OP"
					"NOT":
						state = "NOT_NEXT"
					_:
						return i
			"OP":
				match t:
					"COMPARE", "LOGIC":
						state = "VALUE"
					"DO":
						do_count += 1
						state = "ACTION"
					_:
						return i
			"ACTION":
				if t != "BUTTON":
					return i
				state = "DONE"
			"DONE":
				return i
		i += 1

	if state != "DONE":
		return cubes.size() - 1
	if do_count != 1:
		return cubes.size() - 1
	return -1

# ------------------------------------------------------------
# Вычисление (shunting-yard)
# ------------------------------------------------------------

func _evaluate(cubes: Array) -> Array:
	var values: Array = []
	var ops: Array = []
	var action: Node = null
	var past_do := false
	var i := 0

	while i < cubes.size():
		var cb = cubes[i]
		var t: String = cb.type

		if past_do:
			if t == "BUTTON":
				action = cb.get_value(true)
			i += 1
			continue

		match t:
			"MONITOR":
				values.append(cb.get_value())
				i += 1
			"DIGIT":
				# Серия DIGIT — одно число. Первый — единицы, второй — десятки.
				var n := 0
				var mult := 1
				while i < cubes.size() and cubes[i].type == "DIGIT":
					n += int(cubes[i].get_value()) * mult
					mult *= 10
					i += 1
				values.append(n)
			"BUTTON":
				values.append(bool(cb.get_value(false)))
				i += 1
			"NOT":
				_push_op("NOT", ops, values)
				i += 1
			"COMPARE":
				_push_op(cb.get_value(), ops, values)
				i += 1
			"LOGIC":
				_push_op(cb.get_value(), ops, values)
				i += 1
			"DO":
				_reduce_all(ops, values)
				if values.is_empty() or not bool(values[0]):
					return []
				past_do = true
				i += 1
			_:
				i += 1

	if action == null:
		return []
	return [action]

func _find_action(cubes: Array) -> Node:
	for i in cubes.size():
		if cubes[i].type == "DO":
			if i + 1 < cubes.size() and cubes[i + 1].type == "BUTTON":
				return cubes[i + 1].get_value(true)
			return null
	return null

func _push_op(op: String, ops: Array, values: Array) -> void:
	var prec := _precedence(op)
	while not ops.is_empty() and _can_reduce(ops[-1], values) and _precedence(ops[-1]) >= prec:
		_apply_top(ops, values)
	ops.append(op)

func _can_reduce(op: String, values: Array) -> bool:
	if op == "NOT":
		return values.size() >= 1
	return values.size() >= 2

func _reduce_all(ops: Array, values: Array) -> void:
	while not ops.is_empty():
		_apply_top(ops, values)

func _apply_top(ops: Array, values: Array) -> void:
	var op: String = ops.pop_back()
	if op == "NOT":
		if values.is_empty():
			return
		values[-1] = not bool(values[-1])
		return
	if values.size() < 2:
		return
	var b = values.pop_back()
	var a = values.pop_back()
	values.append(_apply_op(a, b, op))

func _apply_op(a, b, op: String) -> bool:
	match op:
		">": return float(a) > float(b)
		"<": return float(a) < float(b)
		"=": return is_equal_approx(float(a), float(b))
		"≠": return not is_equal_approx(float(a), float(b))
		"AND": return bool(a) and bool(b)
		"OR": return bool(a) or bool(b)
		"XOR": return bool(a) != bool(b)
		"IMP": return not bool(a) or bool(b)
	return false

func _precedence(op: String) -> int:
	match op:
		"NOT": return 3
		">", "<", "=", "≠": return 2
		"AND", "OR", "XOR", "IMP": return 1
	return 0

# ------------------------------------------------------------
# Сигналы кнопок Play (из .tscn)
# ------------------------------------------------------------

func _on_raw_1_button_play_pressed() -> void: _on_row_play($Row1)
func _on_row_2_button_play_pressed() -> void: _on_row_play($Row2)
func _on_row_3_button_play_pressed() -> void: _on_row_play($Row3)
func _on_row_4_button_play_pressed() -> void: _on_row_play($Row4)
