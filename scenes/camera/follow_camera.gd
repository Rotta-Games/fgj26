extends Camera2D

@export var target: Node2D
@export var viewport : SubViewportContainer

var _checkpoint_reached : bool = false
var _checkpoint_limit: int = 999999999

const CAMERA_MOVE_THRESHOLD: int = 100
const CHECKPOINT_THRESHOLD_PERCENTAGE: float = 0.75

signal checkpoint_reached

func _ready() -> void:
	_init_camera()
	
func _init_camera() -> void:
	if not target:
		printerr("Target missing from camera")
		return
	global_position.x = target.global_position.x 
	

func _process(delta: float) -> void:
	if not target:
		return

	var canvas_transform = get_viewport().get_canvas_transform()
	var global_screen_left = -canvas_transform.origin.x
	limit_left = global_screen_left
	var target_screen_left = target.global_position.x - global_screen_left
	if target_screen_left >= CAMERA_MOVE_THRESHOLD:
		global_position.x = target.global_position.x 

	if not _checkpoint_reached and (global_screen_left + get_viewport().get_visible_rect().size.x) >= _checkpoint_limit:
		_checkpoint_reached = true
		checkpoint_reached.emit()

func _on_stage_camera_right_limit_changed(new_right_limit: int) -> void:
	var delta = new_right_limit - limit_right
	_checkpoint_limit = new_right_limit - int((1.0 - CHECKPOINT_THRESHOLD_PERCENTAGE) * new_right_limit)
	limit_right = new_right_limit
	_checkpoint_reached = false
