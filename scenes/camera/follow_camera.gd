extends Camera2D


@export var target: Node2D
@export var viewport : SubViewportContainer

var _actual_cam_pos: Vector2

func _ready() -> void:
	pass

func _process(delta: float) -> void:
	if not target:
		return
		
	_actual_cam_pos = _actual_cam_pos.lerp(target.global_position, delta * 3)
	var cam_subpixel_offset = Vector2((_actual_cam_pos.round() - _actual_cam_pos).x, 0.0)
	viewport.material.set_shader_parameter("cam_offset", cam_subpixel_offset)
	global_position.x = _actual_cam_pos.round().x

func _on_stage_camera_limit_changed(left: int, right: int) -> void:
	limit_right = right
	limit_left = left
