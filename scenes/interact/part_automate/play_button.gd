extends StaticBody3D

signal play_pressed
# Called when the node enters the scene tree for the first time.

func click():
	play_pressed.emit()
