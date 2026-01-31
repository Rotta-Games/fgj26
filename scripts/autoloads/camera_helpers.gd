extends Node

func get_camera_bounds() -> Rect2i:
	var rect : Rect2i
	var canvas_transform = get_viewport().get_canvas_transform()
	rect.position.x = -canvas_transform.origin.x
	rect.position.y = -canvas_transform.origin.y
	rect.size.x = get_viewport().get_window().size.x
	rect.size.x = get_viewport().get_window().size.y
	return rect


func get_camera_left_border() -> int:
	var canvas_transform = get_viewport().get_canvas_transform()
	return int(-canvas_transform.origin.x)
