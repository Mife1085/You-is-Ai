extends StaticBody3D

var busy_pos_list = {}
var Rows_status = {}

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for Row in get_children():
		match Row.name.remove_chars("0123456789"):
			"Row":
				Row.button_play_pressed.connect(check_and_play.bind(Row))
				#Row.button_ready.connect(play.bind(Row))
				Row.row_check.connect(play.bind(Row))
				Rows_status[Row] = {}
				Rows_status[Row].assign({"check": false, "start": false, "cubes": [], "buttons": []})
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

const ROWS := 4
const COLS := 9
const X_START := 0.0
const X_STEP  := 0.6
const Y_START := 3.0
const Y_STEP  := -0.8
const Z       := -0.475

## Позиция ячейки по (row, col) — считается на лету
static func cell(row_col: Vector2i) -> Vector3:
	return Vector3(X_START + row_col[1] * X_STEP, Y_START + row_col[0] * Y_STEP, Z)

## Мгновенный поиск: округляем x и y до ближайшего индекса.
static func nearest_fast(pos: Vector3) -> Vector2i:
	var c := int(round((pos.x - X_START) / X_STEP))
	var r := int(round((pos.y - Y_START) / Y_STEP))

	# Вне диапазона — отдаём (-1, -1)
	if r < 0 or r >= ROWS or c < 0 or c >= COLS:
		return Vector2i(r, c)

	return Vector2i(r, c)

func snap(cube: RigidBody3D):
	if cube not in $Cube_check.get_overlapping_bodies():
		cube.in_automate = false
		busy_pos_list.erase(cube)
		return
	cube.freeze = true
	cube.in_automate = true
	var angle = rotation_degrees if cube.look_me else Vector3(0, int(round(cube.rotation_degrees.y/90))*90, 0)
	
	var pos = nearest_fast(to_local(cube.global_position))
	if busy_pos_list.find_key(pos) and busy_pos_list.get(cube) != pos:
		cube.freeze = false
		cube.apply_central_impulse(Vector3(20, 0, 0))
		#tween.tween_property(cube, "global_position:x", global_position.x+2, 0.5)
		#tween.tween_property(cube, "global_position:x", global_position.y+2, 0.5)
		return
	busy_pos_list[cube] = pos
	pos = to_global(cell(pos))
	
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(cube, "global_position", pos, 0.5)
	tween.tween_property(cube, "rotation_degrees", angle, 0.5)

func _on_cube_check_body_entered(cube) -> void:
	if cube.is_in_group("Cube"):
		if not cube.is_drag:
			snap(cube)

#func _on_cube_check_body_exited(cube: Node3D) -> void:
	#if cube.is_in_group("Cube"):
		#if cube in busy_pos_list.keys():
			#Rows_status[get_child(busy_pos_list[cube][0]-1)].check = false
			#busy_pos_list.erase(cube)

func check_and_play(Row):
	Row.press()
	if Row.is_press:
		var result = check_valid(Row)
		Row.anim_error(result)
		await Row.animation_finish
		if result == 0:
			Row.timer.start()
		else:
			Row.timer.stop()
			Row.Big_lamp_enable(false)
	else:
		Row.timer.stop()
		Row.Big_lamp_enable(false)

func check_valid(Row):
	var have_do = false
	var cubes = []
	cubes.resize(COLS)
	var row_y = nearest_fast(Row.global_position)[0] - 1 # Находим строку
	for cube in busy_pos_list.keys():
		if busy_pos_list[cube][0] == row_y:
			cubes[busy_pos_list[cube][1]] = cube
			if cube.type == "DO":
				if have_do:
					return busy_pos_list[cube][1]
				have_do = true
	var analis = cubes.filter(func(a): return a != null)
	if len(analis) < 3 or not have_do: return -1
	var ci = 0
	for cube in analis:
		var i = cubes.find(cube)
		var next_cube = analis.get(ci+1)
		if cube.type in ["MONITOR", "BUTTON"]:
			if next_cube:
				if next_cube.type not in ["COMPARE", "LOGIC", "DO"]:
					return i
				if next_cube.type == "COMPARE":
					if next_cube.get_value() == "x":
						return i
	
		if cube.type == "DIGIT":
			if next_cube:
				if next_cube.type not in ["DIGIT", "COMPARE", "LOGIC", "DO"]:
					return i
				if next_cube.type == "COMPARE":
					if next_cube.get_value() == "x":
						return i		

		if cube.type in ["COMPARE", "LOGIC"]:
			if not next_cube: return i
			if next_cube.type not in ["MONITOR", "DIGIT", "BUTTON"]: return i
			if next_cube.type == "COMPARE":
				if next_cube.get_value() != "x":
					return i
		if cube.type == "DO":
			if next_cube:
				if not next_cube: return i
				if next_cube.type == "COMPARE":
					if next_cube.get_value() != "x":
						return i
				if next_cube.type not in ["BUTTON"]: return i

	Rows_status[Row].cubes = analis
	return 0 # Проверка прошла успешно и без ошибок

func play(Row):
	if not Row.is_press:
		Row.timer.stop()
		Row.Big_lamp_enable(false)
		return
	Row.timer.start()
	var cubes = Rows_status[Row].cubes
	var buttons = Rows_status[Row].buttons
	var analys = []
	var have_do = false
	var i = 0
	while i < len(cubes):
		match cubes[i].type:
			"MONITOR": analys.append(cubes[i].get_value())
			"DIGIT":
				var summ = ""
				while i < len(cubes):
					if cubes[i].type == "DIGIT":
						summ += str(cubes[i].get_value())
						i += 1
					else:
						i -= 1 # первым проверяться сам куб его индекс считаться в конце
						break
				analys.append(int(summ))
			"BUTTON":
				if have_do:
					var btn = cubes[i].get_value(true)
					if btn == null: hold_buttons(buttons, false)
					analys.append(btn) # obj кнопка
					if btn not in buttons:
						buttons.append(btn)
				else:
					analys.append(cubes[i].get_value(false)) # флаг is_pressed
			"COMPARE":
				var value = cubes[i].get_value()
				if value == "x":
					var b = cubes.get(i+1)
					if b == null: hold_buttons(buttons, false)
					b = b.get_value()
					if typeof(b) not in [TYPE_INT, TYPE_FLOAT, TYPE_BOOL]: hold_buttons(buttons, false)
					analys.append(not bool(b))
				else:
					var a = analys.pop_back()
					var b = cubes.get(i+1)
					for n in [a, b]:
						if n == null: hold_buttons(buttons, false)
					b = b.get_value()
					for n in [a, b]:
						if typeof(n) not in [TYPE_INT, TYPE_FLOAT, TYPE_BOOL]: hold_buttons(buttons, false)
					a = float(a)
					b = float(b)
					match value:
						">": analys.append(a > b)
						"=": analys.append(a == b)
						"=": analys.append(a == b)
						"<": analys.append(a < b)
				i += 1
				
			"LOGIC":
				var a = analys.pop_back()
				var b = cubes.get(i+1)
				if null in [a, b]: hold_buttons(buttons, false)
				b = b.get_value()
				for n in [a, b]:
					if typeof(n) not in [TYPE_INT, TYPE_FLOAT, TYPE_BOOL]: hold_buttons(buttons, false)
				a = bool(a)
				b = bool(b)
				match cubes[i].get_value():
					"OR": analys.append(a or b)
					"AND": analys.append(a and b)
					"XOR": analys.append(a != b)
					"IMP": analys.append(a < b)
				i += 1
			"DO":
				if i == 0: hold_buttons(buttons, false)
				var a = analys.pop_back()
				if bool(a) != true: hold_buttons(buttons, false)
				have_do = true
				analys.append("do")
		i += 1
	
	print(analys) # good result == [true, "do", Button]
	Rows_status[Row].buttons = buttons
	hold_buttons(buttons, true)

func hold_buttons(buttons: Array, is_hold: bool):
	if not buttons.is_empty():
		for btn in buttons:
			btn.hold(is_hold, true) # automate=true
func change_row(cube):
	pass
