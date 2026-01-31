extends Area2D



func _on_area_entered(area: Area2D) -> void:
	if "PlayerHitbox" in area.get_groups():
		var player = area.get_parent()
		player.init_tiger_power()
		queue_free()
