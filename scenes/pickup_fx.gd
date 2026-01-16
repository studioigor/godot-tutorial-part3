extends GPUParticles2D

@export var extra_time: float = 0.2

func _ready() -> void:
	one_shot = true
	emitting = true
	await get_tree().create_timer(lifetime + extra_time).timeout
	queue_free()
