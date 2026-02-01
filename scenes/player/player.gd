extends CharacterBody2D

@export var player_stats: PlayerStats
@export var camera: Camera2D

const SPEED = 150.0
const JUMP_VELOCITY = -400.0
const SPRITE_WIDTH : int = 32
const MIN_Y : int = 85
const MAX_Y : int = 150

const CRIT_VOLUME : float = 10.0
const CRIT_PITCH : float = 0.5

const MAX_COMBO := 3

@onready var fist_box = $FistBox2D
@onready var fist_collision = $FistBox2D/FistBoxCullision2D
@onready var sprite = $AnimatedSprite2D
@onready var head_attachment: Sprite2D = sprite.get_node("HeadAttachment")
@onready var stunned_timer: Timer = $StunnedTimer
@onready var attack_delay_timer: Timer = $AttackDelayTimer
@onready var mask_timer: Timer = $MaskTimer
@onready var attack_sound: AudioStreamPlayer2D = $AttackSound
@onready var kick_sound: AudioStreamPlayer2D = $KickSound
@onready var attack_woosh_sound: AudioStreamPlayer2D = $AttackWooshSound
@onready var damage_taken_sound: AudioStreamPlayer2D = $DamageTakenSound
@onready var player_death_sound: AudioStreamPlayer2D = $PlayerDeathSound
@onready var mask_anim_player: AnimationPlayer = $MaskAnimationPlayer
@onready var animation_player = $AnimationPlayer
@onready var particle_emitter = $ParticleEmitter
@onready var fire_emitter = $FireEmitter

var state: Types.PlayerState = Types.PlayerState.IDLE
var health: int
var direction := Vector2.ZERO
var score: int = 0
var default_attack_volume : float
var default_attack_pitch: float
var player_id = Types.PlayerId

var combo_timer: Timer
var combo_count: int = 0
var attack_hit: bool = false

var player_mask: Types.PlayerMask = Types.PlayerMask.NONE
var mask_stats = {
	Types.PlayerMask.NONE: {
		"attack_speed": 1.0,
		"attack_range": 1.0,
		"damage_multiplier": 1.0,
		"mask_texture": null,
	},
	Types.PlayerMask.TIGER: {
		"attack_speed": 0.7,
		"attack_range": 0.8,
		"damage_multiplier": 0.95,
		"mask_texture": preload("res://assets/gfx/tiger_mask.png"),
	},
	Types.PlayerMask.FIRE: {
		"attack_speed": 1.3,
		"attack_range": 2.0,
		"damage_multiplier": 1.2,
		"mask_texture": preload("res://assets/gfx/fire_mask.png"),
	},
}
const BASE_DAMAGE := 5
var punch_delay: float = 0.1
var kick_delay: float = 0.2
const AFTER_KICK_DELAY := 0.3

# actions
var PLAYER_LEFT: String
var PLAYER_RIGHT: String
var PLAYER_UP: String
var PLAYER_DOWN: String
var PLAYER_ATTACK: String


func _ready() -> void:
	health = player_stats.health
	# actions for player N
	var i = player_stats.player_id
	player_id = player_stats.player_id
	PLAYER_LEFT = "player%d_left" % i
	PLAYER_RIGHT = "player%d_right" % i
	PLAYER_UP = "player%d_up" % i
	PLAYER_DOWN = "player%d_down" % i
	PLAYER_ATTACK = "player%d_attack" % i
	sprite.animation_finished.connect(_on_animation_finished)
	stunned_timer.timeout.connect(_on_stunned_timer_timeout)
	default_attack_volume = attack_sound.volume_db
	default_attack_pitch = attack_sound.pitch_scale
	

	combo_timer = Timer.new()
	combo_timer.one_shot = true
	combo_timer.wait_time = 0.7
	combo_timer.timeout.connect(combo_timer_reset)
	add_child(combo_timer)

	# the tiny delay after button press before attack actually hits
	attack_delay_timer.timeout.connect(func():
		self.fist_collision.disabled = false
	)


func combo_timer_reset() -> void:
	combo_count = 0
	attack_hit = false
	print("combo timer reset")


func _physics_process(_delta: float) -> void:
	if (state == Types.PlayerState.STUNNED or state == Types.PlayerState.DEAD):
		return

	var sped = SPEED
	if state == Types.PlayerState.ATTACKING:
		sped = SPEED * 0.5

	direction = Input.get_vector(PLAYER_LEFT, PLAYER_RIGHT, PLAYER_UP, PLAYER_DOWN)
	if direction.x:
		velocity.x = direction.x * sped
	else:
		velocity.x = move_toward(velocity.x, 0, sped)

	if direction.y:
		velocity.y = direction.y * SPEED
	else:
		velocity.y = move_toward(velocity.y, 0, sped)

	_move()

	if state != Types.PlayerState.ATTACKING:
		if direction != Vector2.ZERO:
			state = Types.PlayerState.WALKING
			play_animation("walk")
			if direction.x != 0:
				var facing_left := direction.x < 0
				sprite.scale.x = -1 if facing_left else 1
				if facing_left:
					particle_emitter._direction = -1 
					particle_emitter.position.x = -player_stats.hit_reach - 3
					fire_emitter._direction = -1
					fire_emitter.position.x = -player_stats.hit_reach - 3
					fist_box.scale.x = -abs(fist_box.scale.x)
				else:
					particle_emitter._direction = 1
					particle_emitter.position.x = player_stats.hit_reach + 3
					fire_emitter._direction = 1
					fire_emitter.position.x = player_stats.hit_reach + 3
					fist_box.scale.x = abs(fist_box.scale.x)
		else:
			state = Types.PlayerState.IDLE
			play_animation("default")


func _move():
	
	move_and_slide()

	# keep player inside screen bounds
	var canvas_transform = get_viewport().get_canvas_transform()
	var global_screen_left = -canvas_transform.origin.x
	var global_screen_right = global_screen_left + get_viewport_rect().size.x
	position.x = clamp(position.x, global_screen_left + SPRITE_WIDTH / 2, global_screen_right - SPRITE_WIDTH / 2)
	position.y = clamp(position.y, MIN_Y, MAX_Y)


func get_attack_speed_multiplier() -> float:
	var combo_mult = 0.6 ** combo_count
	return mask_stats[player_mask]["attack_speed"] * combo_mult

func get_damage_multiplier() -> float:
	return mask_stats[player_mask]["damage_multiplier"]

func get_attack_range_multiplier() -> float:
	return mask_stats[player_mask]["attack_range"]

func _input(event: InputEvent) -> void:
	if (state == Types.PlayerState.DEAD):
		return
		
	if event.is_action_pressed(PLAYER_ATTACK):
		if state in [Types.PlayerState.STUNNED, Types.PlayerState.ATTACKING]:
			return

		var atk_speed_mult = get_attack_speed_multiplier()

		state = Types.PlayerState.ATTACKING
		if combo_count < MAX_COMBO:
			attack_delay_timer.wait_time = punch_delay * atk_speed_mult
			attack_delay_timer.start()
			play_animation("left_punch", 1.0/atk_speed_mult)
			_play_attack_miss_sound()
			if player_mask == Types.PlayerMask.FIRE:
				fire_emitter.fire(3, 1.0)
		else:
			attack_delay_timer.wait_time = kick_delay * atk_speed_mult
			attack_delay_timer.start()
			play_animation("right_kick")
			if player_mask == Types.PlayerMask.FIRE:
				fire_emitter.fire(5, 1.2)
				play_animation("left_punch")

		if combo_count > MAX_COMBO:
			
			particle_emitter.fire(6, 1.4)
			print("combo reset")
			combo_count = 0
			combo_timer.stop()
		elif combo_count > MAX_COMBO - 1:
			particle_emitter.fire(2)
		elif combo_count > MAX_COMBO - 2:
			particle_emitter.fire(1)

	if event.is_action_released(PLAYER_ATTACK) and attack_hit:
		attack_hit = false
		combo_timer.start()
		combo_count += 1


func hurt(amount: int, critical_hit: bool = false) -> void:
	if (state == Types.PlayerState.DEAD):
		return
	
	health -= amount
	
	SignalBus.playerHealthState.emit({
		"player_id": player_id,
		"health": health,
	})

	if (health <= 0):
		print("Player dead!")
		_play_player_death_sound()
		state = Types.PlayerState.DEAD
		sprite.play("stunned")
		animation_player.play("dead")
		
	else:
		sprite.play("stunned")
		_play_player_damage_sound()
		stunned_timer.start(player_stats.stunned_time)
		velocity = Vector2.ZERO
		state = Types.PlayerState.STUNNED
		self.fist_collision.disabled = true
		combo_timer.stop()
		combo_count = 0
		attack_hit = false
		print("Player stunned!")

func init_power(mask_type: Types.PlayerMask) -> void:
	player_mask = mask_type
	head_attachment.texture = mask_stats[mask_type]["mask_texture"]
	head_attachment.visible = true
	fist_box.scale.x = fist_box.scale.x * get_attack_range_multiplier()
	mask_timer.start()

func init_tiger_power() -> void:
	init_power(Types.PlayerMask.TIGER)


func init_fire_power() -> void:
	init_power(Types.PlayerMask.FIRE)

func die() -> void:
	# dead.emit()
	await player_death_sound.finished
	SignalBus.playerStartChange.emit(player_id, false)
	queue_free()

func _get_hit_volume(volume : float, combo_count : int) -> float:
	if combo_count >= MAX_COMBO:
		return volume + CRIT_VOLUME
	if combo_count >= MAX_COMBO -1:
		return volume + 0.66 * CRIT_VOLUME
	if combo_count >= MAX_COMBO -2:
		return volume + 0.33 * CRIT_VOLUME
	if combo_count >= MAX_COMBO -3:
		return volume + 0.22 * CRIT_VOLUME
	if combo_count >= MAX_COMBO -4:
		return volume + 0.11 * CRIT_VOLUME
	return volume

func _get_hit_pitch(pitch : float, combo_count : int) -> float:
	if combo_count >= MAX_COMBO:
		return pitch + CRIT_PITCH
	if combo_count >= MAX_COMBO -1:
		return pitch + 0.66 * CRIT_PITCH
	if combo_count >= MAX_COMBO -2:
		return pitch + 0.33 * CRIT_PITCH
	return pitch

func _on_fist_hit_enemy(area: Area2D) -> void:
	var groups = area.get_groups()

	if "EnemyHitbox" in groups:
		var enemy = area.get_parent()
		attack_hit = true
		var volume = _get_hit_volume(default_attack_volume, combo_count)
		var pitch = _get_hit_pitch(default_attack_pitch, combo_count)

		var dmg_mult = get_damage_multiplier()
		var dmg = (BASE_DAMAGE * dmg_mult) + combo_count * 2
		var given_score

		if combo_count >= MAX_COMBO:
			dmg += 10  # bonus damage for 4 hit combo
			print("Critical Hit!")
			given_score = enemy.hurt(dmg, true)
			#volume *= CRIT_VOLUME
			_play_kick_sound()
		else:
			_play_punch_sound(volume, pitch)
			given_score= enemy.hurt(dmg)
		
		if given_score:
			score = score + given_score
			SignalBus.playerScoreState.emit({
				"player_id": player_id,
				"score": score,
			})
		print("Dealt %d damage!" % dmg)
	if "StaticObjectHitbox" in groups:
		var static_object = area.get_parent()
		attack_hit = true
		
		var dmg = 10 + combo_count * 2
		if combo_count >= 4:
			dmg += 10  # bonus damage for 4 hit combo
			print("Critical Hit on object!")
			static_object.hurt(dmg)
			_play_kick_sound()
		else:
			static_object.hurt(dmg)
			_play_punch_sound(default_attack_volume, default_attack_pitch)

		print("Dealt %d damage to object!" % dmg)


func _on_animation_finished() -> void:
	if sprite.animation == "left_punch":
		state = Types.PlayerState.IDLE
		self.fist_collision.disabled = true
	elif sprite.animation == "right_kick":
		play_animation("default")
		state = Types.PlayerState.STUNNED
		stunned_timer.start(AFTER_KICK_DELAY)
		self.fist_collision.disabled = true


func _on_stunned_timer_timeout():
	if (health > 0):
		state = Types.PlayerState.IDLE
		
func _play_punch_sound(volume: float, pitch: float):
	attack_sound.pitch_scale = pitch + randf_range(-0.1, 0.1)
	attack_sound.volume_db = volume
	attack_sound.play()

func _play_kick_sound():
	kick_sound.pitch_scale = randf_range(0.8, 1.2)
	# kick_sound.volume_db = volume
	kick_sound.play()


func play_animation(anim_name: String, speed_scale: float = 1.0) -> void:
	sprite.speed_scale = speed_scale
	sprite.play(anim_name)
	if mask_anim_player.has_animation(anim_name):
		mask_anim_player.speed_scale = speed_scale
		mask_anim_player.play(anim_name)

func _play_attack_miss_sound():
	attack_woosh_sound.pitch_scale = randf_range(0.8, 1.2)
	attack_woosh_sound.play()
	
func _play_player_damage_sound():
	damage_taken_sound.pitch_scale = randf_range(0.8, 1.2)
	damage_taken_sound.play()

func _play_player_death_sound():
	player_death_sound.play()

func _on_mask_timer_timeout() -> void:
	player_mask = Types.PlayerMask.NONE
	fist_box.scale.x = sign(fist_box.scale.x) * get_attack_range_multiplier()
	head_attachment.visible = false
