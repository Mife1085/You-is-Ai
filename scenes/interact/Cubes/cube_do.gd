extends Cube

func _ready() -> void:
	super._ready()
	type = "DO"
	look_me = true

func interact_alt() -> void:
	me_touch.emit()

func get_value():
	return "do"
