extends TextureRect

const FLICKER_TIME : float = 0.33
const FLICKER_TIMES : int = 5

var _first_time : bool = true

func _on_stage_camera_right_limit_changed(right_limit: int) -> void:
	if _first_time:
		_first_time = false
		return
	for i in range(FLICKER_TIMES):
		self.show()
		await get_tree().create_timer(FLICKER_TIME).timeout
		self.hide()
		await get_tree().create_timer(FLICKER_TIME).timeout
