extends StaticBody3D

var busy_pos_list = {}
var Rows_status = {}

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for Row in get_children():
		match Row.name.remove_chars("0123456789"):
			"Row":
				Row.button_play_pressed.connect(check_and_play.bind(Row))
				Row.button_ready.connect(play.bind(Row))
				Rows_status[Row] = {}
				Rows_status[Row].assign({"check": false, "start": false, "cubes": []})
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
	#var xform = cell(1, 1)
	#PhysicsServer3D.body_set_state(get_rid(), PhysicsServer3D.BODY_STATE_TRANSFORM, xform)

func _on_cube_check_body_entered(cube) -> void:
	if cube.is_in_group("Cube"):
		if not cube.is_drag:
			snap(cube)

func _on_cube_check_body_exited(cube: Node3D) -> void:
	print(cube)
	if cube.is_in_group("Cube"):
		if cube in busy_pos_list.keys():
			Rows_status[get_child(busy_pos_list[cube][0]-1)].check = false
			prints(Rows_status[get_child(busy_pos_list[cube][0]-1)])
			busy_pos_list.erase(cube)

func check_and_play(Row):
	Row.press()
	if not Rows_status[Row]["check"]:
		var result = check_valid(Row)
		if result == 0:
			Rows_status[Row].check = true
			Rows_status[Row].start = true
		print("Row.anim_error(result)")
		Row.anim_error(result)
	else:
		Rows_status[Row].start = Row.is_press
		Row.Big_lamp_enable(true)
		await get_tree().create_timer(1).timeout
		Row.Big_lamp_enable(false)
		#Row.press()
			
	print(Rows_status[Row])
		
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
	cubes = cubes.filter(func(a): return a != null)
	if cubes.is_empty() or not have_do: return -1
	print(cubes)
	var i = 0
	while i > 0:
		match cubes[i].type:
			"MONITOR":
				var test = cubes.get(i+1)
				if test != null:
					if test.type not in ["COMPARE", "LOGIC", "DO"]:
						return i
					if test.type == "COMPARE":
						if test.get_value() == "x":
							return i
			"DIGIT":
				var test = cubes.get(i+1)
				if test != null:
					if test.type not in ["DIGIT", "COMPARE", "LOGIC", "DO"]:
						return i
					if test.type == "COMPARE":
						if test.get_value() == "x":
							return i
			"BUTTON":
				var test = cubes.get(i+1)
				if test != null:
					if test.type not in ["COMPARE", "LOGIC", "DO"]:
						return i
					if test.type == "COMPARE":
						if test.get_value() == "x":
							return i
			"COMPARE":
				var test = cubes.get(i+1)
				if test != null:
					if test.type not in ["MONITOR", "DIGIT", "BUTTON"]:
						return i
				else:
					return i
			"LOGIC":
				var test = cubes.get(i+1)
				if test != null:
					if test.type not in ["MONITOR", "DIGIT", "BUTTON"]:
						return i
				else:
					return i
			"DO":
				var test = cubes.get(i+1)
				if test != null:
					if test.type not in ["MONITOR", "BUTTON"]:
						return i
				else:
					return i
	Rows_status[Row].cubes = cubes
	return 0 # Проверка прошла успешно и без ошибок
	#cubes.sort_custom(func(a, b): return a[1][1] < b[1][1])
	#cubes = cubes.map(func(a): return a[0])

func play(Row):
	var cubes = Rows_status[Row].cubes
	var left_side = []
	var rigth_side = []
	var analys = []
	var have_do = false
	var i = 0
	while i < len(cubes):
		match cubes[i].type:
			"MONITOR": analys.append(cubes[i].get_value())
			"DIGIT":
				var summ = ""
				while i < len(cubes):
					print(cubes[i].type)
					if cubes[i].type == "DIGIT":
						summ += str(cubes[i].get_value())
						i += 1
					else:
						i -= 1 # 
						break
				analys.append(int(summ))
			"BUTTON":
				if have_do:
					analys.append(cubes[i].get_value(true)) # obj
				else:
					var btn_cube = cubes[i].get_value(false) # is_pressed
					if btn_cube:
						analys.append(btn_cube)
					else:
						return i
			"COMPARE":
				var value = cubes[i].get_value()
				if value == "x":
					var b = cubes.get(i+1)
					if b == null:
						return i
					b = b.get_value()
					if typeof(b) not in [TYPE_INT, TYPE_FLOAT, TYPE_BOOL]:
						return i
					analys.append(not b)
				else:
					var a = analys.get(i-1)
					var b = cubes.get(i+1)
					for n in [a, b]:
						if n == null:
							return i
					b = b.get_value()
					for n in [a, b]:
						if typeof(n) not in [TYPE_INT, TYPE_FLOAT, TYPE_BOOL]:
							return i
					analys.remove_at(i-1)
					match value:
						">": analys.append(a > b)
						"=": analys.append(a == b)
						"<": analys.append(a < b)
				i += 1
				
			"LOGIC":
				var a = analys.get(i-1)
				var b = cubes.get(i+1)
				for n in [a, b]:
					if n == null:
						return i
				b = b.get_value()
				for n in [a, b]:
					if typeof(n) not in [TYPE_INT, TYPE_FLOAT, TYPE_BOOL]:
						return i
				analys.remove_at(i-1)
				match cubes[i].get_value():
					"OR": analys.append(a or b)
					"AND": analys.append(a and b)
					"XOR": analys.append(a != b)
					"IMP": analys.append(a < b)
			"DO":
				if i == 0: return i
				var a = analys.pop_back()
				if a != true: return i
				have_do = true
				analys.append("do")
		i += 1
	
	print(analys) # good result == [true, "do", Button]
	$Timer.timeout.connect(_on_timer_timeout.bind(Row), CONNECT_ONE_SHOT)
	return true

func _on_timer_timeout(Row) -> void:
	if Rows_status[Row].start:
		Row.Big_lamp_enable(true if play(Row) else false)
		$Timer.start().bind(Row)
