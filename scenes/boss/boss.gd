extends CharacterBody2D
@export var stat: EnemyStats
@export var direction = Direction.LEFT

@onready var sprite = $AnimatedSprite2D
@onready var animation_player = $AnimationPlayer
@onready var player_hit_area: Area2D = $PlayerHitArea
@onready var enemy_hitbox: Area2D = $HitBox
@onready var enemy_death_sound: AudioStreamPlayer2D = $DeathSound
@onready var attack_delay_timer: Timer = $AttackDelayTimer
@onready var bottle_launch_pos : Node2D = $BottleLaunchPosition
@onready var bottle : Sprite2D = $BottleSprite
@onready var bottle_hit_indicator : AnimatedSprite2D = $BottleHitIndicator

@onready var gas_scene : PackedScene = preload("res://scenes/boss/gas.tscn")
@onready var hey_catch_cound = $HeyCatchSound

signal dead

enum Direction {LEFT, RIGHT}
const X_ALIGN_THRESHOLD := 30.0  # When within this bottlemany px of player's x, seek to the side
const Y_LEVEL_THRESHOLD := 20.0  # Aim to be within this many px of player's y
const MAX_THROWS: int = 5
const MIN_THROWS: int = 1
const BOTTLE_TRAVEL_DURATION_S : float = 1.0
const BOTTLE_THROW_MIN_DELAY_S : float = 0.2
const BOTTLE_THROW_MAX_DELAY_S : float = 1.0
const SEEK_DURATION_MIN_DELAY_S : float = 1.0
const SEEK_DURATION_MAX_DELAY_S : float = 3.0
var rng = RandomNumberGenerator.new()

var state = Types.BossState.IDLE
var current_target: CharacterBody2D
var waiting_to_attack: bool = false
var _target_in_hit_area: bool = false
var _damage_dealt_this_round = false
var _throwing_position: Vector2 = Vector2.ZERO
var _throws_remaining : int = 0
var rampaging : bool = false
var seek_duration_remaining : float = -1.0
var throwing_in_progress : bool = false

var health: int = 1000
var movement_speed: float = 60.0
var attack_delay: float = 0.4
var attack_damage: int = 40
var stunned_time: float = 0.05
var score: int = 10000

func _ready() -> void:
	health = stat.health
	attack_delay = stat.attack_delay

	attack_delay_timer.timeout.connect(func():
		waiting_to_attack = false
	)
	_throwing_position = global_position
	bottle_hit_indicator.top_level = true
	bottle.top_level = true
	_handle_direction(Direction.LEFT)
	_play_intro()

	SignalBus.bossHealthState.emit({
		"health": health,
		"max_health": stat.health,
		"visible": true
	})

	
func multiply() -> void:	
	pass

func randf_bell(min_val: float, max_val: float) -> float:
	var sum = randf() + randf() + randf()
	var normalized = sum / 3.0
	return min_val + normalized * (max_val - min_val)
	
func _play_intro():
	var tween = create_tween()
	tween.set_loops(4)
	tween.tween_property(self, "scale", scale * 1.15, 0.15).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(self, "scale", scale, 0.15).set_trans(Tween.TRANS_QUAD)
	await tween.finished
	_change_state(Types.BossState.THROWING)
	
func _change_state(new_state: Types.BossState):
	print("Boss to state " + str(new_state))
	
	# Reset state flags when changing state
	rampaging = false
	throwing_in_progress = false
	
	match new_state:
		Types.BossState.THROWING:
			hey_catch_cound.play()
			_throws_remaining = round(randf_bell(float(MIN_THROWS), float(MAX_THROWS)))
		
		Types.BossState.SEEK:
			seek_duration_remaining = randf_bell(SEEK_DURATION_MIN_DELAY_S, SEEK_DURATION_MAX_DELAY_S)
			print("seek duration " + str(seek_duration_remaining))

		Types.BossState.RAMPAGE:
			print("RAMPAGE")
	
	state = new_state
	
		
func _physics_process(_delta: float) -> void:
	if state == Types.BossState.RETURN_TO_THROWING:
		_return_to_throwing()
	elif state == Types.BossState.THROWING:
		_handle_throw_state()
	elif state == Types.BossState.RAMPAGE:
		_handle_rampage_state()
	elif current_target && state == Types.BossState.SEEK:
		_handle_seek_state(_delta)
	elif state == Types.BossState.ATTACK:
		seek_duration_remaining -= _delta
		if current_target && _target_in_hit_area && !waiting_to_attack:
			_start_attack()
		elif sprite.animation == "attack" && sprite.frame == 3 && waiting_to_attack &&  _target_in_hit_area && !_damage_dealt_this_round:
			_deal_damage()
	elif !current_target:
		_set_nearest_player_as_target()
		
func _return_to_throwing() -> void:
	if global_position.distance_to(_throwing_position) < 5.0:
		_change_state(Types.BossState.THROWING)
	else:
		_move_towards(_throwing_position)


func _handle_rampage_state() -> void:
	if rampaging:
		return
	rampaging = true
	
	var hitbox := current_target.get_node_or_null("HitBox2D") as Area2D
	if not hitbox:
		_change_state(Types.BossState.RETURN_TO_THROWING)
		return
		
	var to_player := hitbox.global_position - global_position
	var desired_x: float
	if to_player.x >= 0 && abs(to_player.x) >= X_ALIGN_THRESHOLD:
		desired_x = 1
	elif to_player.x <= 0 && abs(to_player.x) >= X_ALIGN_THRESHOLD:
		desired_x = -1
	
	var direction : Direction = get_direction(desired_x, global_position.x)
	_handle_direction(direction)
	animation_player.play("rampage")
	
	# Calculate screen bounds
	var canvas_transform = get_viewport().get_canvas_transform()
	var global_screen_left = -canvas_transform.origin.x
	var global_screen_right = global_screen_left + get_viewport_rect().size.x
	
	# Determine target edge based on direction
	var target_x: float
	const SPRITE_WIDTH = 64
	if direction == Direction.RIGHT:
		target_x = global_screen_right - SPRITE_WIDTH / 2
	else:
		target_x = global_screen_left + SPRITE_WIDTH / 2
	
	# Calculate rampage duration based on distance
	var distance = abs(target_x - global_position.x)
	var rampage_duration = distance / (movement_speed * 4.0)
	
	# Tween to the edge
	var tween = create_tween()
	tween.tween_property(self, "global_position:x", target_x, rampage_duration).set_trans(Tween.TRANS_LINEAR)
	await tween.finished
	
	# Check if still in rampage state (might have been interrupted)
	if state == Types.BossState.RAMPAGE:
		_switch_to_random_next_attack()
	
func _switch_to_random_next_attack() -> void:
	var coinflip : int = randi_range(0, 10)
	if coinflip <= 3:
		_change_state(Types.BossState.SEEK)
	elif coinflip <= 8:
		_change_state(Types.BossState.THROWING)
	else:
		_change_state(Types.BossState.RAMPAGE)
	

func _handle_throw_state() -> void:
	if throwing_in_progress:
		return
	
	if _throws_remaining <= 0:
		_switch_to_random_next_attack()
		return
	
	_perform_throw_attack()
		
func _handle_seek_state(_delta: float) -> void:
	seek_duration_remaining -= _delta
	if seek_duration_remaining <= 0.0:
		_switch_to_random_next_attack()
		return
	var hitbox := current_target.get_node_or_null("HitBox2D") as Area2D
	if hitbox:
		_move_towards(hitbox.global_position)
		
func _move_towards(pos: Vector2) -> void:
	var to_player := pos - global_position
	
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
		velocity = move_dir.normalized() * movement_speed
	
	var direction : Direction = get_direction(desired_x, pos.x)
	_handle_direction(direction)
	
	var flib = direction != Direction.RIGHT
	sprite.flip_h = flib
	if flib:
		player_hit_area.position.x = -40
	else:
		player_hit_area.position.x = 0
	move_and_slide()
			
func _handle_direction(direction : Direction) -> void:		
		var flib = direction != Direction.RIGHT
		sprite.flip_h = flib
		if flib:
			player_hit_area.position.x = -40
		else:
			player_hit_area.position.x = 0

		
func get_direction(desired_x: int, enemy_position_x: float) -> Direction:
	if (desired_x == 0 && global_position.x < enemy_position_x):
		return Direction.RIGHT
	elif (desired_x == 0 && global_position.x > enemy_position_x):
		return Direction.RIGHT
	else:
		return Direction.LEFT if desired_x < 0 else Direction.RIGHT

func _perform_throw_attack() -> void:
	if waiting_to_attack:
		return
	waiting_to_attack = true
	throwing_in_progress = true
	sprite.play("throw")
	await get_tree().create_timer(0.5).timeout

	var target_position = _randomize_bottle_target()
	_launch_bottle(bottle_launch_pos.global_position, target_position)
	

func _launch_bottle(launch_pos : Vector2, target_pos : Vector2):
	bottle.global_position = launch_pos
	bottle.show()
	
	# Position and fade in the hit indicator
	bottle_hit_indicator.global_position = target_pos
	bottle_hit_indicator.modulate.a = 0.5
	bottle_hit_indicator.show()
	bottle_hit_indicator.play("default")
	
	# Fade indicator to full visibility
	var indicator_tween = create_tween()
	indicator_tween.tween_property(bottle_hit_indicator, "modulate:a", 1.0, BOTTLE_TRAVEL_DURATION_S)
	
	# Calculate high arc peak point (way overhead)
	var distance = abs(target_pos.x - launch_pos.x)
	var peak_x = launch_pos.x + (target_pos.x - launch_pos.x) * 0.5
	var peak_y = min(launch_pos.y, target_pos.y) - distance * 1.2
	var peak = Vector2(peak_x, peak_y)
	
	# Create arc motion for bottle
	var tween = create_tween()
	
	# First half: throw up to peak
	tween.tween_property(bottle, "global_position", peak, BOTTLE_TRAVEL_DURATION_S * 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	
	# Second half: fall from peak to target
	tween.tween_property(bottle, "global_position", target_pos, BOTTLE_TRAVEL_DURATION_S * 0.55).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	
	await tween.finished
	_throws_remaining -= 1
	_process_bottle_hit()


func _process_bottle_hit():
	var center = bottle.global_position
	var radius = 15  # Distance from center

	var gas1 = gas_scene.instantiate()
	gas1.top_level = true
	add_child(gas1)
	gas1.global_position = center + Vector2(radius, 0)  # Right

	var gas2 = gas_scene.instantiate()
	gas2.top_level = true
	add_child(gas2)
	gas2.global_position = center + Vector2(0, radius)  # Bottom

	var gas3 = gas_scene.instantiate()
	gas3.top_level = true
	add_child(gas3)
	gas3.global_position = center + Vector2(-radius, 0)  # Left

	var gas4 = gas_scene.instantiate()
	gas4.top_level = true
	add_child(gas4)
	gas4.global_position = center + Vector2(0, -radius)  # Top
	
	bottle.hide()
	bottle_hit_indicator.hide()
	
	var delay = randf_bell(BOTTLE_THROW_MIN_DELAY_S, BOTTLE_THROW_MAX_DELAY_S)
	await get_tree().create_timer(delay).timeout
	waiting_to_attack = false
	throwing_in_progress = false
	
func _randomize_bottle_target() -> Vector2:
	var players := get_tree().get_nodes_in_group("Player")
	var target := Vector2.ZERO
	
	# 80% chance to target a player, 20% chance random throw
	if randf() < 0.8 and not players.is_empty():
		var player = players.pick_random()
		target = player.global_position
		target.x += randf_bell(-30, 30)
		target.y += randf_bell(-20, 20)
	else:
		target.x = randf_range(50, self.global_position.x)
		target.y = randf_range(100, 130)
	
	# Clamp to game bounds
	target.x = clampf(target.x, 50, self.global_position.x)
	target.y = clampf(target.y, 100, 130)
	
	return target
	
func _start_attack() -> void:
	waiting_to_attack = true
	_damage_dealt_this_round = false
	sprite.play("attack")

func _deal_damage() -> void:
	for area in player_hit_area.get_overlapping_areas():
		if "PlayerHitbox" in area.get_groups():
			var player := area.get_parent()
			if "Player" in player.get_groups() && player.has_method("hurt"):
				print("HURT PLAYER")
				player.hurt(attack_damage)
	_damage_dealt_this_round = true
	attack_delay_timer.wait_time = attack_delay
	attack_delay_timer.start()


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

func _die() -> void:
	_disable_all_collisions()
	_change_state(Types.BossState.DEAD)
	sprite.play("default")
	sprite.stop()
	animation_player.play("dead")
	enemy_death_sound.pitch_scale = randf_range(0.5, 1.2)
	enemy_death_sound.play()
	SignalBus.boss_killed.emit()

func remove_enemy() -> void:
	dead.emit()
	await enemy_death_sound.finished
	queue_free()


func _disable_all_collisions() -> void:
	collision_layer = 0
	collision_mask = 0
	$EnemyCollision.set_deferred("disabled", true)
	$HitBox/CollisionShape2D.set_deferred("disabled", true)
	
func _on_player_detection_area_area_entered(area: Node2D) -> void:
	if "PlayerHitbox" in area.get_groups() && state == Types.BossState.IDLE:
		current_target = area.get_parent()

func _on_player_hit_area_area_entered(area: Node2D) -> void:
	if state != Types.BossState.SEEK:
		return
	if "PlayerHitbox" in area.get_groups():
		if area.get_parent() == current_target:
			_target_in_hit_area = true
			if state == Types.BossState.SEEK:
				_change_state(Types.BossState.ATTACK)


func _on_player_hit_area_area_exited(area: Node2D) -> void:
	if state == Types.BossState.ATTACK && "PlayerHitbox" in area.get_groups():
		if seek_duration_remaining > 0.0 and area.get_parent() == current_target:
			_target_in_hit_area = false
			state = Types.BossState.SEEK
		elif seek_duration_remaining <= 0.0:
			_switch_to_random_next_attack()

func hurt(amount: int, critical_hit: bool = false, combo_count: int = 0) -> void:
	if state == Types.BossState.DEAD:
		return

	health -= amount
	SignalBus.bossHealthState.emit({
		"health": health,
		"max_health": stat.health,
		"visible": true
	})

	if (health <= 0):
		_die()
	else:
		animation_player.play("hurt")


func _on_animated_sprite_2d_animation_finished() -> void:
	if sprite.animation == "attack":
		_damage_dealt_this_round = false
		waiting_to_attack = false
