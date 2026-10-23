extends Node3D

@onready var ROOM = get_parent()
@onready var timer = $Monitor
@onready var cur = $Monitor2
@onready var lim = $Monitor3
var Monitors = []
var Cube_Button = []
var Cube_Monitor = []
var Buttons = []
var is_win = false
var color_set = false
var button_pressed = false
var automate_pressed = false
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	timer.value = 1000.0
	lim.value = 0.0
	cur.value = 0.0
	for child in get_children():
		match child.name.remove_chars("0123456789"):
			"Monitor": Monitors.append(child)
			"Button": Buttons.append(child)
			"Cube_Button": Cube_Button.append(child)
			"Cube_Monitor": Cube_Monitor.append(child)
	for cm in Cube_Monitor:
		cm.max_monitors = len(Monitors) - 1
	for cb in Cube_Button:
		cb.setup(Buttons)
	$guast.start()
	$win.start()
	
var delta
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	delta = _delta
	ROOM.progress($win.time_left, $win.wait_time)
	timer.value -= 5 * delta # passiv
	
	if timer.value <= 0:
		set_process(false)
		ROOM.flashing(false)
	
	if button_pressed:
		if lim.value > 0:
			cur.value += 2
		else:
			timer.value -= 2
			$guast.start()
		$drind_ready.start()
		if not automate_pressed:
			$win.start()


func _on_button_pressed() -> void:
	button_pressed = true

func _on_button_not_pressed() -> void:
	button_pressed = false

func _on_button_automate_pressed() -> void:
	automate_pressed = true

func _on_button_automate_not_pressed() -> void:
	automate_pressed = false
	
func _on_guast_timeout() -> void:
	var r = randi_range(2, 6)
	lim.value = r * 100
	$wait.wait_time = r * 2
	$wait.start()

func _on_wait_timeout() -> void:
	var dis = lim.value/2 - abs(lim.value - cur.value)
	if dis == 0:
		return
	elif dis < 0:
		$win.start()
	#if dis / lim.value < 0.6:
		#dis += lim.value - dis
	#else:
		#dis = -dis
	timer.value += dis
	cur.value = 0.0
	lim.value = 0.0
	$wait.stop()
	$guast.start()


func _on_drind_ready_timeout() -> void:
	$wait.stop()
	_on_wait_timeout()


func _on_win_timeout() -> void:
	if is_win:
		return
	ROOM.flashing(true)
	is_win = true
	set_process(false)

func get_button_with_color(color):
	for b in Buttons:
		if color == b.get_color():
			return b
