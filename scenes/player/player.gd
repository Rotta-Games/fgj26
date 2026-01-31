extends CharacterBody2D

@export var player_stats: PlayerStats
@export var camera: Camera2D

const SPEED = 150.0
const JUMP_VELOCITY = -400.0
const SPRITE_WIDTH : int = 32
const MIN_Y : int = 85
const MAX_Y : int = 150

const MAX_COMBO := 4

@onready var fist_box = $FistBox2D
@onready var fist_collision = $FistBox2D/FistBoxCullision2D
@onready var sprite = $AnimatedSprite2D
@onready var head_attachment: Sprite2D = sprite.get_node("HeadAttachment")
@onready var stunned_timer: Timer = $StunnedTimer
@onready var attack_delay_timer: Timer = $AttackDelayTimer
@onready var attack_sound: AudioStreamPlayer2D = $AttackSound
@onready var attack_woosh_sound: AudioStreamPlayer2D = $AttackWooshSound
@onready var mask_anim_player: AnimationPlayer = $MaskAnimationPlayer
@onready var animation_player = $AnimationPlayer

var state: Types.PlayerState = Types.PlayerState.IDLE
var health: int
var direction := Vector2.ZERO

var combo_timer: Timer
var combo_count: int = 0
var attack_hit: bool = false

var player_mask: Types.PlayerMask = Types.PlayerMask.NONE
var attack_stats = {
	Types.PlayerMask.NONE: {"attack_speed": 1.0},
	Types.PlayerMask.TIGER: {"attack_speed": 0.7, "damage_multiplier": 0.95},
	Types.PlayerMask.FIRE: {"attack_speed": 1.0, "damage_multiplier": 1.2},
}
const BASE_DAMAGE := 5
var punch_delay: float = 0.1
var kick_delay: float = 0.2

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
	PLAYER_LEFT = "player%d_left" % i
	PLAYER_RIGHT = "player%d_right" % i
	PLAYER_UP = "player%d_up" % i
	PLAYER_DOWN = "player%d_down" % i
	PLAYER_ATTACK = "player%d_attack" % i
	sprite.animation_finished.connect(_on_animation_finished)
	stunned_timer.timeout.connect(_on_stunned_timer_timeout)

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
	if state == Types.PlayerState.STUNNED:
		return

	direction = Input.get_vector(PLAYER_LEFT, PLAYER_RIGHT, PLAYER_UP, PLAYER_DOWN)
	if direction.x:
		velocity.x = direction.x * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	if direction.y:
		velocity.y = direction.y * SPEED
	else:
		velocity.y = move_toward(velocity.y, 0, SPEED)

	_move()
	
	if state != Types.PlayerState.ATTACKING:
		if direction != Vector2.ZERO:
			state = Types.PlayerState.WALKING
			play_animation("walk")
			if direction.x != 0:
				var facing_left := direction.x < 0
				sprite.scale.x = -1 if facing_left else 1
				if facing_left:
					fist_box.position.x = -player_stats.hit_reach
				else:
					fist_box.position.x = player_stats.hit_reach
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
	return attack_stats[player_mask]["attack_speed"]


func _input(event: InputEvent) -> void:
	if event.is_action_pressed(PLAYER_ATTACK):
		if state in [Types.PlayerState.STUNNED, Types.PlayerState.ATTACKING]:
			return

		var atk_speed_mult = get_attack_speed_multiplier()

		state = Types.PlayerState.ATTACKING
		if combo_count < MAX_COMBO:
			attack_delay_timer.wait_time = punch_delay * atk_speed_mult
			attack_delay_timer.start()
			play_animation("left_punch")
			_play_attack_miss_sound()
		else:
			attack_delay_timer.wait_time = kick_delay * atk_speed_mult
			attack_delay_timer.start()
			play_animation("right_kick")

	if event.is_action_released(PLAYER_ATTACK) and attack_hit:
		attack_hit = false
		combo_timer.start()
		combo_count += 1
		if combo_count > MAX_COMBO:
			print("combo reset")
			combo_count = 0
			combo_timer.stop()


func hurt(amount: int, critical_hit: bool = false) -> void:
	health -= amount

	SignalBus.playerHealthState.emit({
		"player_id": Types.PlayerId.PLAYER_1,
		"health": health,
	})

	if (health <= 0):
		print("Player dead!")
		state = Types.PlayerState.DEAD
		sprite.play("stunned")
		animation_player.play("dead")
	else:
		sprite.play("stunned")
		stunned_timer.start(player_stats.stunned_time)
		velocity = Vector2.ZERO
		state = Types.PlayerState.STUNNED
		self.fist_collision.disabled = true
		combo_timer.stop()
		combo_count = 0
		attack_hit = false
		print("Player stunned!")


func init_tiger_power() -> void:
	head_attachment.visible = true
	player_mask = Types.PlayerMask.TIGER


func die() -> void:
	# dead.emit()
	# await enemy_death_sound.finished
	queue_free()


func _on_fist_hit_enemy(area: Area2D) -> void:
	var groups = area.get_groups()

	if "EnemyHitbox" in groups:
		var enemy = area.get_parent()
		attack_hit = true
		_play_punch_sound()

		var dmg = BASE_DAMAGE + combo_count * 2
		if combo_count >= MAX_COMBO:
			dmg += 10  # bonus damage for 4 hit combo
			print("Critical Hit!")
			enemy.hurt(dmg, true)
		else:
			enemy.hurt(dmg)
		print("Dealt %d damage!" % dmg)
	if "StaticObjectHitbox" in groups:
		var static_object = area.get_parent()
		attack_hit = true
		
		var dmg = 10 + combo_count * 2
		if combo_count >= 4:
			dmg += 10  # bonus damage for 4 hit combo
			print("Critical Hit on object!")
			static_object.hurt(dmg)
		else:
			static_object.hurt(dmg)

		print("Dealt %d damage to object!" % dmg)


func _on_animation_finished() -> void:
	if sprite.animation == "left_punch" or sprite.animation == "right_kick":
		state = Types.PlayerState.IDLE
		self.fist_collision.disabled = true


func _on_stunned_timer_timeout():
	if (health > 0):
		state = Types.PlayerState.IDLE
		
func _play_punch_sound():
	attack_sound.pitch_scale = randf_range(0.9, 1.1)
	attack_sound.play()


func play_animation(anim_name: String) -> void:
	var speed_scale = 1.0/get_attack_speed_multiplier()
	sprite.speed_scale = speed_scale
	sprite.play(anim_name)
	if mask_anim_player.has_animation(anim_name):
		mask_anim_player.speed_scale = speed_scale
		mask_anim_player.play(anim_name)

func _play_attack_miss_sound():
	attack_woosh_sound.pitch_scale = randf_range(0.8, 1.2)
	attack_woosh_sound.play()
