extends StaticBody3D

var color: Color = Color.SEA_GREEN
var is_hold = false

signal pressed
signal not_pressed

func _ready() -> void:
	color = Color(randf(), randf(), randf())
	$Button.mesh.material.albedo_color = color
	
#func _physics_process(delta: float) -> void:
	#if is_hold:
		#pressed.emit()
		
func hold(true_hold: bool):
	is_hold = true_hold
	var tween = create_tween()
	tween.set_parallel(true)
	if is_hold:
		pressed.emit()
		tween.tween_property($Button.mesh, "height", 0.01, 0.5)
		tween.tween_property($Button, "position", $Button.position - Vector3(0.025, 0.025, 0), 0.5)
	else:
		not_pressed.emit()
		tween.tween_property($Button.mesh, "height", 0.05, 0.5)
		tween.tween_property($Button, "position", $Button.position + Vector3(0.025, 0.025, 0), 0.5)

func get_color():
	return color
