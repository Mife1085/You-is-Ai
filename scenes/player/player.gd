extends CharacterBody3D

@export var speed: float = 6.0
@export var mouse_sensitivity: float = 0.003
@export var jump_velocity: float = 4.5

@onready var camera: Camera3D = $Camera3D
@onready var ray: RayCast3D = $RayCast3D
@onready var marker: Node3D = $RayCast3D/Marker

var target: Object = null

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("escape"):
		pause()
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		# Горизонтально — крутим всё тело
		rotate_y(-event.relative.x * mouse_sensitivity)
		# Вертикально — только камеру, иначе будет кувыркаться
		camera.rotate_x(-event.relative.y * mouse_sensitivity)
		# Ограничиваем взгляд вверх/вниз ±89°
		camera.rotation.x = clampf(camera.rotation.x, -1.55, 1.55)
	
	if event.is_action_pressed("interact"):
		target = ray.get_collider()
		if target:
			if target.has_method("click") and target.has_method("hold"):
				$One_tap.start()
			elif target.has_method("click"):
				target.click()
			elif target.has_method("hold"):
				target.hold(true)
			get_viewport().set_input_as_handled()
	if event.is_action_released("interact"):
		if target:
			if $One_tap.time_left > 0:
				target.click()
			else:
				if target.has_method("hold"):
					target.hold(false)
	
	if event.is_action_pressed("interact_alt"):
		target = ray.get_collider()
		if target and target.has_method("interact_alt"):
				target.interact_alt()

func _physics_process(delta: float) -> void:
	$HUD.cursor_on_object(ray.get_collider() != null)
	ray.rotation.x = camera.rotation.x
	var dir := Vector3.ZERO
	if Input.is_action_pressed("move_forward"): dir -= global_transform.basis.z
	if Input.is_action_pressed("move_back"):    dir += global_transform.basis.z
	if Input.is_action_pressed("move_left"):    dir -= global_transform.basis.x
	if Input.is_action_pressed("move_right"):   dir += global_transform.basis.x
	dir.y = 0
	dir = dir.normalized()

	velocity.x = dir.x * speed
	velocity.z = dir.z * speed

	if not is_on_floor():
		velocity.y -= 9.8 * delta
	elif Input.is_action_just_pressed("jump"):
		velocity.y = jump_velocity

	move_and_slide()

func pause():
	$HUD.pause()
	if Input.mouse_mode == 2:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
