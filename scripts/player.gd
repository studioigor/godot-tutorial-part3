extends CharacterBody2D

@export var speed: float = 50.0
@onready var anim: AnimatedSprite2D = $AnimatedSprite2D

func _physics_process(delta: float) -> void:
	# В Godot 4 эти экшены уже есть по умолчанию:
	# ui_left/ui_right/ui_up/ui_down (и на них обычно уже повешены и стрелки, и WASD)
	var input_vector := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	
	velocity = input_vector * speed
	move_and_slide()

	# Анимации
	if input_vector.length() > 0.0:
		if anim.animation != "walk":
			anim.play("walk")
	else:
		if anim.animation != "default":
			anim.play("default")

	# Flip по горизонтали (в инспекторе это называется Flip H)
	# "по оси Y" обычно имеют в виду отражение относительно вертикальной оси — это flip_h.
	if input_vector.x != 0.0:
		anim.flip_h = input_vector.x < 0.0
