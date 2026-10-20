extends StaticBody3D

@export_enum("TIMER", "PROGRESS", "Info") var type = "Info"
@export var monitor_index: int = 1
@export var monitor_label: String = "TIMER"
@export var color_screen: Color = Color.GRAY
@export var color_text: Color = Color.DODGER_BLUE

@export var value: float = 0.0:
	set(_value):
		if type == "TIMER":
			if abs(_value - value) > 20:
				flashing(_value > value)
			
		value = _value
		#label.text = "%s\n%7d" % [monitor_label, value]
		if type == "PROGRESS":
			$Value.text = "%3d" % value + "%"
		else:
			$Value.text = "%3d" % value
		
func _ready() -> void:
	$Value.modulate = color_text
	match type:
		"TIMER":
			$Index.text = ""
			$Value.modulate = Color.FIREBRICK
		"PROGRESS":
			$Index.text = ""
		"Info":
			$Index.text = "№ %s" % monitor_index
	$Screen.mesh.material = $Screen.mesh.material.duplicate()
	$Screen.mesh.material.albedo_color = color_screen


func flashing(reward: bool):
	var tween = create_tween()
	if reward:
		tween.tween_property($Screen.mesh.material, "albedo_color", Color.GREEN, 0.4)
	else:
		tween.tween_property($Screen.mesh.material, "albedo_color", Color.RED, 0.4)
	tween.tween_property($Screen.mesh.material, "albedo_color", color_screen, 0.3)
	
