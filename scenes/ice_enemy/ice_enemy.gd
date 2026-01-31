extends CharacterBody2D
@export var stat: EnemyStats
@export var direction = Direction.LEFT

@onready var sprite = $AnimatedSprite2D
@onready var stunned_timer = $StunnedTimer
@onready var animation_player = $AnimationPlayer

signal dead

enum Direction {LEFT, RIGHT}
const X_ALIGN_THRESHOLD := 30.0  # When within this many px of player's x, seek to the side
const Y_LEVEL_THRESHOLD := 10.0  # Aim to be within this many px of player's y

var state = Types.EnemyState.IDLE
var health: int
var current_target: CharacterBody2D
var is_in_hit_area: bool
var x_target_treshold = 20

func _ready() -> void:
	health = stat.health

func _physics_process(_delta: float) -> void:
	if current_target && !is_in_hit_area && state == Types.EnemyState.SEEK:
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
			
			# Ugly way to determine direction
			if (desired_x == 0 && global_position.x < hitbox.global_position.x):
				direction = Direction.LEFT
			elif (desired_x == 0 && global_position.x > hitbox.global_position.x):
				direction = Direction.LEFT
			else:
				direction = Direction.LEFT if desired_x < 0 else Direction.RIGHT
			sprite.flip_h = direction != Direction.RIGHT
			move_and_slide()

func init_spawn(spawn_position: Vector2) -> void:
	global_position = spawn_position
	state = Types.EnemyState.SEEK
	_set_nearest_player_as_target()

func _set_nearest_player_as_target() -> void:
	var players := get_tree().get_nodes_in_group("Player")
	var nearest: Node2D = null
	var nearest_dist_sq := INF
	for node in players:
		if node is CharacterBody2D:
			var d_sq := global_position.distance_squared_to(node.global_position)
			if d_sq < nearest_dist_sq:
				nearest_dist_sq = d_sq
				nearest = node
	if nearest:
		current_target = nearest as CharacterBody2D

func hurt(amount:float) -> void:
	health -= amount
	
	if (health <= 0):
		state = Types.EnemyState.DEAD
		animation_player.play("dead")
	else:
		animation_player.play("hurt")
		stunned_timer.start(stat.stunned_time)
		state = Types.EnemyState.STUNNED

func die() -> void:
	dead.emit()
	queue_free()
	
func _on_player_detection_area_area_entered(area: Node2D) -> void:
	if "PlayerHitbox" in area.get_groups() && state == Types.EnemyState.IDLE:
		current_target = area.get_parent()

func _on_player_hit_area_area_entered(area: Node2D) -> void:
	if area.get_parent() == current_target && state == Types.EnemyState.SEEK:
		state = Types.EnemyState.ATTACK
		is_in_hit_area = true


func _on_player_hit_area_area_exited(area: Node2D) -> void:
		if area.get_parent() == current_target && state == Types.EnemyState.ATTACK:
			state = Types.EnemyState.SEEK
			is_in_hit_area = false


func _on_stunned_timer_timeout():
	if (health > 0):
		state = Types.EnemyState.SEEK
