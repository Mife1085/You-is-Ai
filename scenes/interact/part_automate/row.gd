extends Node3D


## Список лампочек: обычные из $Lamps + $Big_lamp как последняя.
@onready var LampList: Array = $Lamps.get_children() + [$Big_lamp]
@onready var button_holder: Node3D = $Button_start_stop
@onready var timer: Timer = $Timer

var active: bool = false
var is_press: bool = false

const GREEN := Color.LIME_GREEN
const RED := Color.RED

signal button_play_pressed # для проверки валидации
signal animation_finish
signal row_check # нужно проверить строчку и отыграть условие

func _ready() -> void:
	$Button_start_stop/Button.play_pressed.connect(func(): button_play_pressed.emit())
	for lamp in LampList:
		lamp.mesh = lamp.mesh.duplicate()
		lamp.mesh.material = lamp.mesh.material.duplicate()
		lamp.mesh.material.emission_energy_multiplier = 2

func press():
	is_press = not is_press
	var tween = create_tween()
	tween.tween_property($Button_start_stop, "position:z", 0.45 if is_press else 0.6, 0.15)

func anim_error(inx):
	var sec = 0.2
	if inx == 0:
		for lamp in LampList:
			await get_tree().create_timer(sec).timeout
			lamp.mesh.material.emission = GREEN
			lamp.mesh.material.emission_enabled = true
		await get_tree().create_timer(sec*4).timeout
		lamps_off()
		Big_lamp_enable(true, Color.WEB_GRAY)
	elif inx == -1:
		lamps_on(RED)
		await get_tree().create_timer(sec*4).timeout
		lamps_off()
		press()
	else:
		var i = 0
		var limit = min(inx + 2, LampList.size())
		while i < limit:
			if i > len(LampList):
				break 
			await get_tree().create_timer(sec).timeout
			LampList[i].mesh.material.emission = GREEN
			LampList[i].mesh.material.emission_enabled = true
			i += 1
		await get_tree().create_timer(sec*4).timeout
		lamps_on(RED)
		await get_tree().create_timer(sec*4).timeout
		lamps_off()
		press()
	animation_finish.emit()

func Big_lamp_enable(enable: bool, color=GREEN):
	$Big_lamp.mesh.material.emission = color
	$Big_lamp.mesh.material.emission_enabled = enable

func lamps_on(color: Color):
	for lamp in LampList:
		lamp.mesh.material.emission = color
		lamp.mesh.material.emission_enabled = true

func lamps_off():
	for lamp in LampList:
		lamp.mesh.material.emission_enabled = false

func _on_timer_timeout() -> void:
	row_check.emit()
