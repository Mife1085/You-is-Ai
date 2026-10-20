extends Cube

func _ready() -> void:
	super._ready()
	type = "DO"
	look_me = true

func interact_alt() -> void:
	pass

func get_value():
	return "do"
