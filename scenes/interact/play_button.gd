extends StaticBody3D

var is_pressed = false
signal play_pressed

func interact(press):
	if press:
		is_pressed = not is_pressed 
		play_pressed.emit(is_pressed)
