extends CharacterBody2D

@export var speed: float = 50.0
@export var knockback_strength: float = 180.0
@export var knockback_damp: float = 600.0

@export var attack_duration: float = 0.2
@export var attack_cooldown: float = 0.35

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var hitbox: Area2D = $Hitbox
@onready var hitbox_shape: CollisionShape2D = $Hitbox/CollisionShape2D
@onready var hurtbox: Area2D = $Hurtbox
@onready var hearts_label: Label = $CanvasLayer/HeartsLabel
@onready var game_over_ui: Panel = $CanvasLayer/Panel

@onready var gm: GameManager = GM

var _knockback_vel: Vector2 = Vector2.ZERO
var _attacking: bool = false
var _attack_cd_left: float = 0.0
var _dead: bool = false


func _ready() -> void:
	add_to_group("player")
	update_boxes_side()

	# Хитбокс выключен по умолчанию
	hitbox_shape.disabled = true

	# Подключим сигнал урона от Hurtbox
	if not hurtbox.damaged.is_connected(_on_damaged):
		hurtbox.damaged.connect(_on_damaged)

	# Подпишемся на GameManager: обновление сердец + game over
	if not gm.lives_changed.is_connected(_on_lives_changed):
		gm.lives_changed.connect(_on_lives_changed)
	if not gm.game_over.is_connected(_on_game_over):
		gm.game_over.connect(_on_game_over)

	# Инициализируем UI текущим значением из GM
	_on_lives_changed(gm.lives)


func _physics_process(delta: float) -> void:
	if _dead:
		return

	_attack_cd_left = maxf(0.0, _attack_cd_left - delta)

	# Атака по пробелу (ui_accept обычно = Space)
	if Input.is_action_just_pressed("ui_accept"):
		if _attack_cd_left <= 0.0 and not _attacking:
			_attack_cd_left = attack_cooldown
			attack()

	var input_vector := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")

	# Flip по горизонтали
	if input_vector.x != 0.0:
		var new_flip := input_vector.x < 0.0
		if anim.flip_h != new_flip:
			anim.flip_h = new_flip
			update_boxes_side()

	# Анимации
	if input_vector.length() > 0.0:
		if anim.animation != "walk":
			anim.play("walk")
	else:
		if anim.animation != "default":
			anim.play("default")

	# Движение + отбрасывание
	var move_vel := input_vector * speed
	velocity = move_vel + _knockback_vel
	move_and_slide()

	# Плавное затухание импульса
	_knockback_vel = _knockback_vel.move_toward(Vector2.ZERO, knockback_damp * delta)


func update_boxes_side() -> void:
	var x := -6.0 if anim.flip_h else 6.0
	hitbox.position.x = x


func _on_damaged(amount: int, attacker: Node2D) -> void:
	if _dead:
		return

	# ВСЕ РАСЧЁТЫ HP УБРАНЫ: просто говорим GameManager "нанеси урон"
	gm.apply_damage(amount)

	# Отбрасывание — можно оставить в игроке (это не расчёт HP)
	if gm.lives > 0:
		var dir := Vector2.ZERO
		if attacker != null and is_instance_valid(attacker):
			dir = (global_position - attacker.global_position).normalized()
		else:
			dir = Vector2.RIGHT if anim.flip_h else Vector2.LEFT
		_knockback_vel = dir * knockback_strength


func attack() -> void:
	_attacking = true
	hitbox_shape.disabled = false
	await get_tree().create_timer(attack_duration).timeout
	hitbox_shape.disabled = true
	_attacking = false


# --- UI сердца (слушаем GameManager) ---
func _on_lives_changed(units: int) -> void:
	update_hearts_units(units)

func update_hearts_units(units: int) -> void:
	var u := maxi(units, 0) # optional safety
	var full_hearts := u >> 1          # same as floor(u / 2)
	var half_heart := u & 1            # same as u % 2

	var s := ""
	for i in range(full_hearts):
		s += "❤️"
	if half_heart == 1:
		s += "💔"

	hearts_label.text = s

# --- GAME OVER ---
func _on_game_over() -> void:
	if _dead:
		return
	_dead = true

	velocity = Vector2.ZERO
	_knockback_vel = Vector2.ZERO

	if is_instance_valid(hitbox_shape):
		hitbox_shape.disabled = true

	set_collision_layer(0)
	set_collision_mask(0)

	if anim.sprite_frames and anim.sprite_frames.has_animation("death"):
		anim.play("death")
		await anim.animation_finished

	Effects.spawn_death_effect(get_tree().current_scene, global_position, global_rotation)
	anim.queue_free()
	
	# Ждём немного, чтобы частицы успели "вспыхнуть" до паузы
	await get_tree().create_timer(1).timeout
	game_over_ui.show()


# (опционально) лечение: тоже без расчётов, просто уведомляем GM
func heal(amount: int) -> void:
	if _dead:
		return
	gm.heal(amount)
