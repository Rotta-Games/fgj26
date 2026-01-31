extends Node2D

@export var blocks : Array[StageBlock]

var _current_camera_limit : int = 0

signal camera_right_limit_changed(right_limit: int)

var _current_block : StageBlock

func _ready() -> void:
	_set_block(blocks.pop_front())
	
func _set_block(block: StageBlock) -> void:
	_current_block = block
	# TODO pistä blockeille suoraan x
	_current_camera_limit += block.length
	camera_right_limit_changed.emit(_current_camera_limit)

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if event.keycode == Key.KEY_ESCAPE:
			get_tree().quit()
