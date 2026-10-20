extends CanvasLayer


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func cursor_on_object(is_true: bool):
	if is_true:
		$Cursor/ColorRect.color = Color.GREEN
	else:
		$Cursor/ColorRect.color = Color.GRAY
	
func pause():
	$Cursor.visible = not $Cursor.visible 
	$ButtonsPanel.visible = not $ButtonsPanel.visible
