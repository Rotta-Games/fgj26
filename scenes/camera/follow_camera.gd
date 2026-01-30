extends Camera2D


@export var target: Node2D
@export var viewport : SubViewportContainer

var actual_cam_pos: Vector2

func _ready() -> void:
	pass


func _process(delta: float) -> void:
	if target:
		actual_cam_pos = actual_cam_pos.lerp(target.global_position, delta * 3)
		var cam_subpixel_offset = Vector2((actual_cam_pos.round() - actual_cam_pos).x, 0.0)

		viewport.material.set_shader_parameter("cam_offset", cam_subpixel_offset)

		global_position.x = actual_cam_pos.round().x
