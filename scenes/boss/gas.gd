extends Node2D

@onready var hit_area = $Area2D
@onready var attack_timer = $AttackTimer
@onready var alive_timer = $AliveTimer
@onready var sprite = $AnimatedSprite2D

# Props
var attack_delay: float = 0.8
var attack_damage: int = 10
var alive_time: float = 1.0

# States
var damage_dealt = false

func _ready() -> void:
	sprite.play("default")
	alive_timer.start(alive_time)

func _physics_process(_delta: float) -> void:
	if !damage_dealt:
		for area in hit_area.get_overlapping_areas():
				if "PlayerHitbox" in area.get_groups():
					var typed_area = area as Area2D
					var player := typed_area.get_parent()
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
