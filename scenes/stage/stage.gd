extends Node2D

@onready var _block_container : Node2D = $Blocks

var _current_camera_limit : int = 0


signal camera_right_limit_changed(right_limit: int)

var _current_block : StageBlock

func _ready() -> void:
	if _block_container.get_children().is_empty():
		printerr("No blocks defined in Stage")
		return
	var first_block = _block_container.get_children()[0]
	_set_block(first_block)
	
func _set_block(block: StageBlock) -> void:
	_current_block = block
	_current_camera_limit = block.global_position.x
	camera_right_limit_changed.emit(_current_camera_limit)

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if event.keycode == Key.KEY_ESCAPE:
			get_tree().quit()
