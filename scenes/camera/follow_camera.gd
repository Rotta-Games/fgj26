extends Camera2D

@export var target: Node2D
@export var viewport : SubViewportContainer

var _actual_cam_pos: Vector2
var _camera_move_theshold: int = 100

func _ready() -> void:
	_init_camera()
	pass
	
func _init_camera() -> void:
	if not target:
		printerr("Target missing from camera")
		return
		
	global_position.x = target.global_position.x 
	

func _process(delta: float) -> void:
	if not target:
		return
		
	# TODO ota käyttöön joskus
	#_actual_cam_pos = _actual_cam_pos.lerp(target.global_position, delta * 3)
	#var cam_subpixel_offset = Vector2((_actual_cam_pos.round() - _actual_cam_pos).x, 0.0)
	#viewport.material.set_shader_parameter("cam_offset", cam_subpixel_offset)
	#global_position.x = _actual_cam_pos.round().x - _camera_left_offset
	
	var canvas_transform = get_viewport().get_canvas_transform()
	var global_screen_left = -canvas_transform.origin.x
	limit_left = global_screen_left
	var target_screen_left = target.global_position.x - global_screen_left
	if target_screen_left >= _camera_move_theshold:
		global_position.x = target.global_position.x 


func _on_stage_camera_right_limit_changed(right_limit: int) -> void:
	limit_right = right_limit
