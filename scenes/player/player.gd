extends CharacterBody2D

@export var player_stats: PlayerStats
@export var camera: Camera2D

const SPEED = 150.0
const JUMP_VELOCITY = -400.0

@onready var fist_box = $FistBox2D
@onready var fist_collision = $FistBox2D/FistBoxCullision2D
@onready var sprite = $AnimatedSprite2D


func _physics_process(delta: float) -> void:
	# Handle jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var direction := Input.get_axis("ui_left", "ui_right")
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	var y_direction := Input.get_axis("ui_up", "ui_down")
	if y_direction:
		velocity.y = y_direction * SPEED
	else:
		velocity.y = move_toward(velocity.y, 0, SPEED)

	move_and_slide()

	if direction != 0 or y_direction != 0:
		sprite.play("walk")
		if direction != 0:
			sprite.flip_h = direction < 0
	else:
		sprite.play("default")


func _input(event):
	if event is InputEventKey and event.pressed:
		if event.is_action_pressed("p1_hit"):
			self.fist_collision.disabled = false
			print("PUNCH!")

func _process(_delta):
	self.fist_collision.disabled = true


func _on_fist_hit_enemy(area: Area2D) -> void:
	# ennemy.hurt(player_stats.attack_power_or_jotain)
	pass
