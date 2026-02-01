extends Node2D

@onready var hit_area = $Area2D
@onready var attack_timer = $AttackTimer
@onready var disable_attack_timer = $DisableAttackTimer
@onready var alive_timer = $AliveTimer
@onready var sprite = $AnimatedSprite2D
@onready var gas_sound = $GasSound

# Props
var attack_delay: float = 0.6
var attack_damage: int = 25
var alive_time: float = 1.0

var no_more_damage : bool = false

# States
var damage_dealt = false

func _ready() -> void:
	sprite.play("default")
	gas_sound.pitch_scale = randf_range(0.9,1.1)
	gas_sound.play()
	alive_timer.start(alive_time)

func _physics_process(_delta: float) -> void:
	if !damage_dealt and !no_more_damage:
		for player in hit_area.get_overlapping_bodies():
			if "Player" in player.get_groups():
				var typed_area = player as CharacterBody2D
				if "Player" in player.get_groups() && player.has_method("hurt"):
					player.hurt(attack_damage)
					damage_dealt = true
					attack_timer.start(attack_delay)
						

func _disable_all_collisions() -> void:
	$Area2D/CollisionShape2D.set_deferred("disabled", true)


func _on_attack_timer_timeout():
	damage_dealt = false


func _on_alive_timer_timeout():
	queue_free()


func _on_disable_attack_timer_timeout() -> void:
	no_more_damage = true
