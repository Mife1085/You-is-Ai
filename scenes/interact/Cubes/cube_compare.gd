extends Cube

var value = 0

func _ready() -> void:
	super._ready()
	type = "COMPARE"

func interact_alt():
	value = (value + 1) % 4
	_apply_pose(value)

func _apply_pose(mode: int) -> void:
	# mode: 0 = "x", 1 = "<", 2 = "="
	var tween := create_tween()
	tween.set_parallel(true)
	var t = 0.25
	#var change = []
	print(mode)
	match mode:
		0:
			tween.tween_property($BlueStick, "position:x", -0.08, t)
			tween.tween_property($RedStick, "position:x", -0.08, t)
			tween.tween_property($BlueStick, "position:y", 0.08, t)
			tween.tween_property($RedStick, "position:y", -0.08, t)
			tween.tween_property($BlueStick, "rotation_degrees:z", -45, t)
			tween.tween_property($RedStick, "rotation_degrees:z", 45, t)
		1:
			tween.tween_property($BlueStick, "position:x", -0.1, t)
			tween.tween_property($RedStick, "position:x", -0.1, t)
			tween.tween_property($BlueStick, "rotation_degrees:z", -22.5, t)
			tween.tween_property($RedStick, "rotation_degrees:z", 22.5, t)
		2:
			tween.tween_property($BlueStick, "position:x", -0.11, t)
			tween.tween_property($RedStick, "position:x", -0.11, t)
			tween.tween_property($BlueStick, "rotation_degrees:z", 0, t)
			tween.tween_property($RedStick, "rotation_degrees:z", 0, t)
		3:
			tween.tween_property($BlueStick, "position:y", 0, t)
			tween.tween_property($RedStick, "position:y", 0, t)
			tween.tween_property($BlueStick, "rotation_degrees:z", 22.5, t)
			tween.tween_property($RedStick, "rotation_degrees:z", -22.5, t)
			
		

func _tween_pivot(pivot: Node3D, target_z: float) -> void:
	var tw := create_tween()
	#tw.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(pivot, "rotation:z", target_z, 0.25)

func get_value():
	return ["x", ">", "=", "<"][value]
