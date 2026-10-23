extends Cube

var value: int = 0

func _ready() -> void:
	super._ready()
	type = "DIGIT"
	look_me = true
	$Digit.mesh = $Digit.mesh.duplicate()

func interact_alt() -> void:
	me_touch.emit()
	value = (value + 1) % 10
	$Digit.mesh.text = str(value)


func get_value():
	return value
