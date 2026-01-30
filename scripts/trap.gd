extends AnimatedSprite2D

@onready var hitbox_shape: CollisionShape2D = $Hitbox/CollisionShape2D

func _ready() -> void:
	hitbox_shape.disabled = true
	_pulse()

func _pulse() -> void:
	while true:
		hitbox_shape.disabled = false
		await get_tree().create_timer(0.15).timeout
		hitbox_shape.disabled = true
		await get_tree().create_timer(1.85).timeout
