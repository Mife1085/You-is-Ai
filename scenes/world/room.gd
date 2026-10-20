extends Node3D

@onready var LEVEL_SCENE = load("res://scenes/world/Level%s.tscn" % [Game.current_level])
@onready var HelloLabel = $Control/Label
@onready var Progress = $Progress
@onready var Player = $Player
@onready var Automate = $Automate

var win: bool = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	add_child(LEVEL_SCENE.instantiate())
	HelloLabel.text = "Level:%s \nTry:%s " % [Game.current_level, Game.current_try]
	HelloLabel.modulate = Color.TRANSPARENT
	var tween = create_tween()
	tween.tween_property(HelloLabel, "modulate", Color.WHITE, 3)
	tween.tween_property(HelloLabel, "modulate", Color.TRANSPARENT, 3)

func flashing(reward: bool):
	$DirectionalLight3D.visible = true
	win = reward
	var tween = create_tween()
	tween.parallel().tween_property($DirectionalLight3D, "light_energy", 1, 1)

	if reward:
		tween.tween_property($DirectionalLight3D, "light_color", Color.GREEN, 1)
	else:
		tween.tween_property($DirectionalLight3D, "light_color", Color.RED, 1)
	tween.tween_property($DirectionalLight3D, "light_color", Color.WHITE, 1)
	
	await tween.finished
	$Timer.start()
	flashing(win)


func _on_timer_timeout() -> void:
	if win:
		print("старт анимации, сейф, после новый левел")
		Game.current_level += 1
	else:
		restart()

func restart():
	Game.current_try += 1
	get_tree().reload_current_scene()

func progress(cur: float, target: float):
	if cur == 0.0:
		$Progress.value = 0
		return
	$Progress.value = 100-cur/target*100


func _on_area_3d_body_exited(body: Node3D) -> void:
	body.global_position = Vector3(0, 5, 0)
	if body.is_in_group("Cube"):
		body.linear_velocity = Vector3.ZERO
