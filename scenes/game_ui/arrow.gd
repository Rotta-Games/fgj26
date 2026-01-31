extends TextureRect

@export var flicker_duration : float = 0.33
@export var flicker_times : int = 5

var _first_time : bool = true

func _on_stage_camera_right_limit_changed(right_limit: int) -> void:
	if _first_time:
		_first_time = false
		return
	for i in range(flicker_times):
		self.show()
		await get_tree().create_timer(flicker_duration).timeout
		self.hide()
		await get_tree().create_timer(flicker_duration).timeout
