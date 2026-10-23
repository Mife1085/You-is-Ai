extends Cube

@export var value: int = 0
@onready var label = $Value
var max_monitors: int = 0
var monitors_list = []

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	type = "MONITOR"
	super._ready()
	label.text = "№ 1"
	#interact_alt()


## Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta: float) -> void:
	#pass

func interact_alt():
	me_touch.emit()
	value = (value + 1) % max_monitors
	label.text = "№ %s" % (value + 1)

func get_value(): 
	return Level.Monitors.get(value +1).value
