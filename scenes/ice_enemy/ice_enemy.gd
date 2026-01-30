extends CharacterBody2D

@export var stat: EnemyStats

var current_target: CharacterBody2D



func _on_area_2d_body_entered(body: Node2D) -> void:
	if "Player" in body.get_groups():
		print("VOI VITTU")
