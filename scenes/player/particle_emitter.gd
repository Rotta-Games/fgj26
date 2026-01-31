extends Node2D

@onready var _sprite: Sprite2D = $Sprite2D

# Duration settings - snappy and quick for impact feel
@export_group("Duration")
@export var min_duration_s: float = 0.25
@export var max_duration_s: float = 0.35

# Movement settings - directional punch impact
@export_group("Movement")
@export var spawn_radius: float = 5.0  # Small radius for tight cluster
@export var horizontal_min: float = 25.0  # Slower particle speed
@export var horizontal_max: float = 45.0  # Reduced from 70
@export var spread_angle: float = 45.0  # Cone angle in degrees (wider spread for more vertical variation)

# Visual settings - subtle variation
@export_group("Visuals")
@export var scale_min: float = 0.8
@export var scale_max: float = 1.2
@export var rotation_speed_min: float = -180.0  # Moderate spin
@export var rotation_speed_max: float = 180.0

# Pool for reuse (optional optimization)
var _sprite_pool: Array[Sprite2D] = []
var _direction: int = 1  # 1 = right, -1 = left

func _ready() -> void:
	_sprite.hide()
	z_index = 100  # Render particles above Y-sorted enemies

# Flip particle emission direction (call when player turns)
func flip() -> void:
	_direction *= -1

func fire(amount: int, base_scale: float = 1.0) -> void:
	for i in range(amount):
		var sprite: Sprite2D = _sprite.duplicate()
		# Add to root instead of self so particles stay in world space
		get_tree().root.add_child(sprite)
		_sprite_pool.append(sprite)
		
		# Use global position for spawn location
		var spawn_angle: float = randf() * TAU
		var spawn_distance: float = randf() * spawn_radius
		sprite.global_position = global_position + Vector2(
			cos(spawn_angle) * spawn_distance,
			sin(spawn_angle) * spawn_distance
		)
		
		# Random scale variation, multiplied by base_scale from caller
		var random_scale: float = randf_range(scale_min, scale_max) * base_scale
		sprite.scale = Vector2(random_scale, random_scale)
		
		sprite.show()
		
		# Random duration
		var duration: float = randf_range(min_duration_s, max_duration_s)
		
		# Directional movement - fire in a cone towards punch direction
		# Base angle is 0° (right), spread creates a cone
		var angle_spread: float = randf_range(-spread_angle, spread_angle)
		var angle_rad: float = deg_to_rad(angle_spread)
		
		var distance: float = randf_range(horizontal_min, horizontal_max)
		var displacement_x: float = cos(angle_rad) * distance * _direction  # Multiply by direction
		var displacement_y: float = sin(angle_rad) * distance
		
		# Straight movement in cone direction (no arc)
		var tween_x: Tween = get_tree().create_tween()
		tween_x.tween_property(sprite, "global_position:x", sprite.global_position.x + displacement_x, duration)
		
		var tween_y: Tween = get_tree().create_tween()
		tween_y.tween_property(sprite, "global_position:y", sprite.global_position.y + displacement_y, duration)
		
		# Random rotation for more dynamic feel
		var tween_rotation: Tween = get_tree().create_tween()
		var rotation_speed: float = randf_range(rotation_speed_min, rotation_speed_max)
		var total_rotation: float = deg_to_rad(rotation_speed * duration)
		tween_rotation.tween_property(sprite, "rotation", sprite.rotation + total_rotation, duration)
		
		# Fade out at the end - stay bright for 80% then fade fast
		var tween_fade: Tween = get_tree().create_tween()
		tween_fade.tween_interval(duration * 0.8)  # Wait for 80% of duration
		tween_fade.tween_property(sprite, "modulate:a", 0.0, duration * 0.2)  # Fade in last 20%
		
		# Clean up sprite after animation completes
		tween_fade.finished.connect(_on_particle_finished.bind(sprite))

func _on_particle_finished(sprite: Sprite2D) -> void:
	_sprite_pool.erase(sprite)
	sprite.queue_free()

# Optional: Clean up all active particles (useful for cleanup or resets)
func clear_all_particles() -> void:
	for sprite in _sprite_pool:
		if is_instance_valid(sprite):
			sprite.queue_free()
	_sprite_pool.clear()
