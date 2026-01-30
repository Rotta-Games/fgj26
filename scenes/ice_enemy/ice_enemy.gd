extends CharacterBody2D

@export var stat: EnemyStats

var current_target: CharacterBody2D
var is_in_hit_area: bool

func _physics_process(delta: float) -> void:
	if current_target && !is_in_hit_area:
		var direction = (current_target.global_position - global_position).normalized()
		velocity = direction * stat.speed
		move_and_slide()
		

func _on_player_detection_area_body_entered(body: Node2D) -> void:
	if "Player" in body.get_groups():
		current_target = body


func _on_player_hit_area_body_entered(body):
	if body == current_target:
		is_in_hit_area = true


func _on_player_hit_area_body_exited(body):
	if body == current_target:
		is_in_hit_area = false
