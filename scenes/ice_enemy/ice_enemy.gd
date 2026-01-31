extends CharacterBody2D
@export var stat: EnemyStats
@export var direction = Direction.LEFT

@onready var sprite = $AnimatedSprite2D
@onready var stunned_timer = $StunnedTimer
@onready var animation_player = $AnimationPlayer
@onready var player_hit_area: Area2D = $PlayerHitArea
@onready var enemy_hitbox: Area2D = $HitBox
@onready var enemy_death_sound: AudioStreamPlayer2D = $DeathSound
@onready var player_collision : CollisionShape2D = $PlayerCollision
@onready var attack_delay_timer: Timer = $AttackDelayTimer

signal dead

enum Direction {LEFT, RIGHT}
const X_ALIGN_THRESHOLD := 30.0  # When within this many px of player's x, seek to the side
const Y_LEVEL_THRESHOLD := 20.0  # Aim to be within this many px of player's y
var rng = RandomNumberGenerator.new()

var state = Types.EnemyState.IDLE
var health: int
var attack_delay: float
var current_target: CharacterBody2D
var waiting_to_attack: bool = false
var _target_in_hit_area: bool = false
var _damage_dealt_this_round = false

func _ready() -> void:
	health = stat.health
	attack_delay = stat.attack_delay
	
	attack_delay_timer.timeout.connect(func():
		waiting_to_attack = false
	)

func _physics_process(_delta: float) -> void:
	if current_target && state == Types.EnemyState.SEEK:
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
				desired_y = 1 + rng.randf_range(0, 2)
			elif to_player.y <= 0 && abs(to_player.y) >= Y_LEVEL_THRESHOLD:
				desired_y = -1 - rng.randf_range(0, 2)

			var move_dir := Vector2(desired_x, desired_y)
			if move_dir.length_squared() < 0.01:
				velocity = Vector2.ZERO
			else:
				velocity = move_dir.normalized() * stat.movement_speed
			
			# Ugly way to determine direction
			if (desired_x == 0 && global_position.x < hitbox.global_position.x):
				direction = Direction.RIGHT
			elif (desired_x == 0 && global_position.x > hitbox.global_position.x):
				direction = Direction.RIGHT
			else:
				direction = Direction.LEFT if desired_x < 0 else Direction.RIGHT
			
			var flib = direction != Direction.RIGHT
			sprite.flip_h = flib
			if flib:
				player_hit_area.position.x = -40
			else:
				player_hit_area.position.x = 0
			move_and_slide()
	elif current_target && _target_in_hit_area && !waiting_to_attack && state == Types.EnemyState.ATTACK:
		_start_attack()

	if state == Types.EnemyState.ATTACK && sprite.animation == "attack" && sprite.frame == 3 && waiting_to_attack &&  _target_in_hit_area && !_damage_dealt_this_round:
		_deal_damage()


func _start_attack() -> void:
	waiting_to_attack = true
	_damage_dealt_this_round = false
	sprite.play("attack")

func _deal_damage() -> void:
	current_target.hurt(stat.attack_damage)
	_damage_dealt_this_round = true
	attack_delay_timer.wait_time = attack_delay
	attack_delay_timer.start()

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

func hurt(amount: int, critical_hit: bool = false, player: Types.PlayerId = Types.PlayerId.PLAYER_1) -> Variant:
	if state == Types.EnemyState.DEAD:
		return
	
	waiting_to_attack = false
	health -= amount
	
	if (health <= 0):
		_disable_all_collisions()
		state = Types.EnemyState.DEAD
		animation_player.play("dead")
		enemy_death_sound.pitch_scale = randf_range(0.9, 1.1)
		enemy_death_sound.play()
		return stat.score

	else:
		animation_player.play("hurt")
		stunned_timer.start(stat.stunned_time)
		state = Types.EnemyState.STUNNED
		sprite.play("stunned")
		return

func die() -> void:
	dead.emit()
	await enemy_death_sound.finished
	queue_free()

func _disable_all_collisions() -> void:
	# Disable CharacterBody2D collision
	collision_layer = 0
	collision_mask = 0
	$EnemyCollision.disabled = true
	
func _on_player_detection_area_area_entered(area: Node2D) -> void:
	if "PlayerHitbox" in area.get_groups() && state == Types.EnemyState.IDLE:
		current_target = area.get_parent()

func _on_player_hit_area_area_entered(area: Node2D) -> void:
	if "PlayerHitbox" in area.get_groups():
		if area.get_parent() == current_target:
			_target_in_hit_area = true
			if state == Types.EnemyState.SEEK:
				state = Types.EnemyState.ATTACK


func _on_player_hit_area_area_exited(area: Node2D) -> void:
	if state == Types.EnemyState.ATTACK && "PlayerHitbox" in area.get_groups():
		if area.get_parent() == current_target:
			_target_in_hit_area = false
			state = Types.EnemyState.SEEK


func _on_stunned_timer_timeout():
	if (health > 0 && state == Types.EnemyState.STUNNED):
		sprite.play("default")
		state = Types.EnemyState.SEEK
		
		for area in player_hit_area.get_overlapping_areas():
			if current_target == area.get_parent():
				state = Types.EnemyState.ATTACK


func _on_animated_sprite_2d_animation_finished() -> void:
	if sprite.animation == "attack":
		_damage_dealt_this_round = false
		waiting_to_attack = false
		
