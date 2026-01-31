extends CharacterBody2D

@export var player_stats: PlayerStats
@export var camera: Camera2D

const SPEED = 150.0
const JUMP_VELOCITY = -400.0
const SPRITE_WIDTH : int = 32

@onready var fist_box = $FistBox2D
@onready var fist_collision = $FistBox2D/FistBoxCullision2D
@onready var sprite = $AnimatedSprite2D

var direction := Vector2.ZERO
var is_punching := false

# actions
var PLAYER_LEFT: String
var PLAYER_RIGHT: String
var PLAYER_UP: String
var PLAYER_DOWN: String
var PLAYER_ATTACK: String


func _ready() -> void:
	# actions for player N
	var i = player_stats.player_id
	PLAYER_LEFT = "player%d_left" % i
	PLAYER_RIGHT = "player%d_right" % i
	PLAYER_UP = "player%d_up" % i
	PLAYER_DOWN = "player%d_down" % i
	PLAYER_ATTACK = "player%d_attack" % i
	sprite.animation_finished.connect(_on_animation_finished)


func _physics_process(_delta: float) -> void:
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
	
	if not is_punching:
		if direction != Vector2.ZERO:
			sprite.play("walk")
			if direction.x != 0:
				sprite.flip_h = direction.x < 0
		else:
			sprite.play("default")


func _move():
	
	move_and_slide()

	# keep player inside screen bounds
	var canvas_transform = get_viewport().get_canvas_transform()
	var global_screen_left = -canvas_transform.origin.x
	var global_screen_right = global_screen_left + get_viewport_rect().size.x
	position.x = clamp(position.x, global_screen_left + SPRITE_WIDTH / 2, global_screen_right - SPRITE_WIDTH / 2)


func _input(event):
	if (event is InputEventKey or event is InputEventJoypadButton) and event.pressed:
		if event.is_action_pressed(PLAYER_ATTACK):
			self.fist_collision.disabled = false
			is_punching = true
			sprite.play("left_punch")
		if event.is_action_pressed(PLAYER_LEFT):
			self.fist_box.position.x = -player_stats.hit_reach
		elif event.is_action_pressed(PLAYER_RIGHT):
			self.fist_box.position.x = player_stats.hit_reach

func _process(_delta):
	self.fist_collision.disabled = true


func _on_fist_hit_enemy(area: Area2D) -> void:
	if "EnemyHitbox" in area.get_groups():
		print("HIT ENEMY")
		# ennemy.hurt(player_stats.attack_power_or_jotain)


func _on_animation_finished() -> void:
	if sprite.animation == "left_punch":
		is_punching = false
