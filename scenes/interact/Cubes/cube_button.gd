extends Cube

var color_side = []
var value: StaticBody3D = null

@onready var target_side = $Side1

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	super._ready()
	type = "BUTTON"
	look_me = true
	
func setup(button_list):
	for btn in button_list:
		color_side.append(btn.get_color())
		btn.pressed.connect(ligth_side.bind(btn.get_color(), true))
		btn.not_pressed.connect(ligth_side.bind(btn.get_color(), false))
		
	while len(color_side) < 6:
		var color = Color(randf(), randf(), randf()) * 0.5
		if color.get_luminance() > 0.1 and color.get_luminance() < 0.5:
			color_side.append(color)
		
	for i in range(6):
		var side = get_child(i)
		side.mesh = side.mesh.duplicate()
		side.mesh.material = side.mesh.material.duplicate()
		side.mesh.material.albedo_color = color_side[i]
		side.mesh.material.emission = color_side[i]
		side.mesh.material.emission_enabled = false
		side.mesh.material.emission_energy_multiplier = 10

func interact_alt():
	
	color_side.append(color_side.pop_front())
	for i in range(6):
		var side = get_child(i)
		side.mesh.material.albedo_color = color_side[i]

func get_value(obj: bool):
	if obj:
		return Level.get_button_with_color(color_side[0])
	else:
		return target_side.mesh.material.emission_enabled

func ligth_side(color: Color, enable: bool):
	target_side = get_child(color_side.find(color))
	target_side.mesh.material.emission = color
	target_side.mesh.material.emission_enabled = enable
