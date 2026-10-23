class_name Cube
extends RigidBody3D

#enum Type { MONITOR, DIGIT, LOGIC, COMPARE, DO, BUTTON }
var type: String = "null"
var Level
var Room

var look_me = true
var is_drag = false
var in_automate = false

signal me_touch

func _ready() -> void:
	Level = get_parent()
	Room = Level.get_parent()
	add_to_group("Cube")
	freeze_mode = RigidBody3D.FREEZE_MODE_KINEMATIC

func _physics_process(delta: float) -> void:
	if is_drag:
		drag(delta)

var full_drag = false

func drag(delta):
	var marker = Room.Player.marker
	var dis = marker.global_position - global_position
	#var dis =  Room.Player.global_position - global_position
	if dis.x + dis.z < 0.2:
		full_drag = true
	if full_drag:
		global_position = marker.global_position
	else:
		global_position += 5 * dis * delta
	#var tween = create_tween()
	#tween.tween_property(self, "global_position", marker.global_position, dis/12)
	if look_me:
		global_rotation.y = marker.global_rotation.y
		global_rotation.z = marker.global_rotation.z
		
func hold(is_hold):
	if in_automate:
		me_touch.emit()
	freeze = is_hold
	is_drag = is_hold
	full_drag = false
	if not is_hold:
		Room.Automate.snap(self)
