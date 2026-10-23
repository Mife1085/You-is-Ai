extends Node3D


## Список лампочек: обычные из $Lamps + $Big_lamp как последняя.
@onready var LampList: Array = $Lamps.get_children() + [$Big_lamp]
@onready var button_holder: Node3D = $Button_start_stop
@onready var timer: Timer = $Timer

var active: bool = false
var is_press: bool = false

#const COLOR_OFF := Color(0.15, 0.15, 0.15)
const GREEN := Color.LIGHT_GREEN
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
			lamp.mesh.material.emission = Color.LIME_GREEN
			lamp.mesh.material.emission_enabled = true
		await get_tree().create_timer(sec*3).timeout
		lamps_off()
		Big_lamp_enable(true, Color.WEB_GRAY)
		animation_finish.emit()
	elif inx == -1:
		lamps_on(RED)
		await get_tree().create_timer(sec*3).timeout
		lamps_off()
		press()
	else:
		var i = 0
		while i < inx:
			await get_tree().create_timer(sec).timeout
			LampList[i].mesh.material.emission = Color.LIME_GREEN
			LampList[i].mesh.material.emission_enabled = true
			i += 1
		await get_tree().create_timer(sec*2).timeout
		lamps_on(RED)
		await get_tree().create_timer(sec).timeout
		lamps_off()
		press()
	print_debug(inx)

func Big_lamp_enable(enable: bool, color=GREEN):
	$Big_lamp.mesh.material.emission = color
	$Big_lamp.mesh.material.emission_enabled = enable

func _on_timer_timeout() -> void:
	row_check.emit()

func lamps_on(color: Color):
	for lamp in LampList:
		lamp.mesh.material.emission = color
		lamp.mesh.material.emission_enabled = true

func lamps_off():
	for lamp in LampList:
		lamp.mesh.material.emission_enabled = false

#func set_active(on: bool) -> void:
	#active = on
	#var tween := create_tween()
	#tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	#var offset := -0.1 if on else 0.0
#
## ------------------------------------------------------------
## Лампочки
## ------------------------------------------------------------
#
#func lamp_count() -> int:
	#return LampList.size()
#
#func set_lamp(idx: int, color: Color) -> void:
	#if idx < 0 or idx >= LampList.size():
		#return
	#var lamp: MeshInstance3D = LampList[idx]
	#if lamp.material_override == null:
		#lamp.material_override = StandardMaterial3D.new()
	#var m := lamp.material_override as StandardMaterial3D
	#m.albedo_color = color.darkened(0.6)
	#m.emission_enabled = true
	#m.emission = color
	#m.emission_energy_multiplier = 3.0
#
#func clear_lamp(idx: int) -> void:
	#if idx < 0 or idx >= LampList.size():
		#return
	#var lamp: MeshInstance3D = LampList[idx]
	#if lamp.material_override == null:
		#lamp.material_override = StandardMaterial3D.new()
	#var m := lamp.material_override as StandardMaterial3D
	#m.albedo_color = COLOR_OFF
	#m.emission_enabled = false
	#m.emission = Color.BLACK
#
#func clear_lamps() -> void:
	#for i in LampList.size():
		#clear_lamp(i)
#
### Тусклая подсветка — для «ряд активен, но условие ещё не выполнено».
#func set_lamp_dim(idx: int) -> void:
	#if idx < 0 or idx >= LampList.size():
		#return
	#var lamp: MeshInstance3D = LampList[idx]
	#if lamp.material_override == null:
		#lamp.material_override = StandardMaterial3D.new()
	#var m := lamp.material_override as StandardMaterial3D
	#m.albedo_color = Color(0.1, 0.35, 0.15)
	#m.emission_enabled = false
	#m.emission = Color.BLACK
#
### Показать «ряд работает, действие выполняется» — все лампы зелёным.
#func show_running() -> void:
	#for i in LampList.size():
		#set_lamp(i, COLOR_GREEN)
#
### Показать «ряд работает, условие ложно» — все лампы тускло-зелёным.
#func show_running_idle() -> void:
	#for i in LampList.size():
		#set_lamp_dim(i)
