extends CharacterBody2D
@export var stat: EnemyStats
@export var direction = Direction.LEFT

@onready var sprite = $AnimatedSprite2D

enum EnemyState {IDLE, DISABLED, SEEK, ATTACK, STUNNED, WAIT_FOR_ATTACK, JUMP, FLY, DYING}
enum Direction {LEFT, RIGHT}


const X_ALIGN_THRESHOLD := 30.0  # When within this many px of player's x, seek to the side
const Y_LEVEL_THRESHOLD := 10.0  # Aim to be within this many px of player's y

var state = Types.EnemyState.IDLE
var current_target: CharacterBody2D
var is_in_hit_area: bool
var x_target_treshold = 20


var prev_state = null
	
func _physics_process(_delta: float) -> void:
	if state != prev_state:
		prev_state = state

	if current_target && !is_in_hit_area:
		var hitbox := current_target.get_node_or_null("HitBox2D") as Area2D
		if hitbox:
			var to_player := hitbox.global_position - global_position
			
			# Seek X
			var desired_x: float
			if to_player.x >= 0 && abs(to_player.x) >= X_ALIGN_THRESHOLD:
				desired_x = 1
			elif to_player.x <= 0 && abs(to_player.x) >= X_ALIGN_THRESHOLD:
				desired_x = -1
			
			# Seek Y
			var desired_y: float
			if to_player.y >= 0 && abs(to_player.y) >= Y_LEVEL_THRESHOLD:
				desired_y = 1
			elif to_player.y <= 0 && abs(to_player.y) >= Y_LEVEL_THRESHOLD:
				desired_y = -1

			var move_dir := Vector2(desired_x, desired_y)
			if move_dir.length_squared() < 0.01:
				velocity = Vector2.ZERO
			else:
				velocity = move_dir.normalized() * stat.movement_speed

			direction = Direction.LEFT if desired_x < 0 else Direction.RIGHT
			sprite.flip_h = direction != Direction.RIGHT
			move_and_slide()

func init_spawn(spawn_position: Vector2) -> void:
	position = spawn_position
	state = EnemyState.SEEK

func hurt(amount:float) -> void:
	stat.health -= amount
	
	if (stat.healt <= 0):
		die()

func die() -> void:
	pass
	
func _on_player_detection_area_area_entered(area: Node2D) -> void:
	if "PlayerHitbox" in area.get_groups():
		current_target = area.get_parent()

func _on_player_hit_area_area_entered(area: Node2D) -> void:
	if area.get_parent() == current_target:
		state = EnemyState.ATTACK
		is_in_hit_area = true


func _on_player_hit_area_area_exited(area: Node2D) -> void:
		if area.get_parent() == current_target:
			state = EnemyState.SEEK
			is_in_hit_area = false
