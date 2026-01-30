# Effects.gd
extends Node

@export var death_effect_scene: PackedScene = preload("res://scenes/death_effect.tscn")

func spawn_death_effect(world: Node, pos: Vector2, rot: float = 0.0) -> Node:
	var fx := death_effect_scene.instantiate()
	world.add_child(fx)
	fx.global_position = pos
	fx.global_rotation = rot
	
	# Для Godot 4: если это GPUParticles2D/CPUParticles2D
	if fx is GPUParticles2D or fx is CPUParticles2D:
		fx.emitting = true
	else:
		# Если внутри сцены DeathEffect частицы не корневые,
		# можно сделать метод в самой сцене или найти по группе/имени.
		var p = fx.get_node_or_null("Particles")
		if p and (p is GPUParticles2D or p is CPUParticles2D):
			p.emitting = true
	
	# Чтобы эффект сам удалился: либо задай one_shot+lifetime в инспекторе,
	# либо гарантированно убери через таймер:
	var t := get_tree().create_timer(2.0)
	t.timeout.connect(func():
		if is_instance_valid(fx):
			fx.queue_free()
	)
	return fx
