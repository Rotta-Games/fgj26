extends Area2D

@onready var sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	_start_shine_tween()

func _start_shine_tween() -> void:
	var tween = create_tween()
	tween.set_loops()
	# Normal -> bright white flash -> normal
	tween.tween_property(sprite, "modulate", Color(1.5, 1.5, 1.5, 1), 0.15).set_trans(Tween.TRANS_SINE)
	tween.tween_property(sprite, "modulate", Color(1, 1, 1, 1), 0.15).set_trans(Tween.TRANS_SINE)
	tween.tween_interval(1.5)

func _on_area_entered(area: Area2D) -> void:
	if "PlayerHitbox" in area.get_groups():
		var player = area.get_parent()
		player.init_tiger_power()
		queue_free()
