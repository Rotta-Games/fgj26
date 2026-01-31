extends CharacterBody2D
@export var stat: EnemyStats

enum EnemyState {IDLE, DISABLED, SEEK, ATTACK, WAIT_FOR_ATTACK, JUMP, FLY, DYING}

const X_ALIGN_THRESHOLD := 30.0  # When within this many px of player's x, seek to the side
const Y_LEVEL_THRESHOLD := 10.0  # Aim to be within this many px of player's y

var state = EnemyState.IDLE
var current_target: CharacterBody2D
var is_in_hit_area: bool
var x_target_treshold = 20

var prev_state = null

func _physics_process(_delta: float) -> void:
	if state != prev_state:
		prev_state = state
		print(EnemyState.keys()[state])
	if current_target && !is_in_hit_area:
		var hitbox := current_target.get_node_or_null("HitBox2D")
		if hitbox:
			var to_player := current_target.global_position - global_position
			var dx := to_player.x
			var dy := to_player.y

			var desired_x: float
			if abs(dx) <= X_ALIGN_THRESHOLD:
				# Move away from player's x to get to the side (left or right)
				desired_x = sign(global_position.x - current_target.global_position.x)
			else:
				desired_x = sign(dx)

			# Y: move up/down to get to same level as player (within threshold)
			var desired_y: float
			if abs(dy) <= Y_LEVEL_THRESHOLD:
				desired_y = 0.0
			else:
				desired_y = sign(dy)

			var move_dir := Vector2(desired_x, desired_y)
			if move_dir.length_squared() < 0.01:
				velocity = Vector2.ZERO
			else:
				velocity = move_dir.normalized() * stat.speed
			move_and_slide()

func _on_player_detection_area_area_entered(area: Node2D):
	if "PlayerHitbox" in area.get_groups():
		current_target = area.get_parent()


func _on_player_detection_area_area_exited(area: Node2D):
	if area == current_target:
		state = EnemyState.SEEK
		is_in_hit_area = false
