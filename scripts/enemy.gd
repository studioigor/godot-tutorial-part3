extends CharacterBody2D

@export var move_speed: float = 50.0
@export var attack_distance: float = 18.0
@export var attack_cooldown: float = 1.5
@export var return_stop_distance: float = 2.0

@export var hp: int = 30
@export var knockback_strength: float = 180.0
@export var knockback_damp: float = 600.0

@onready var detection_zone: Area2D = $DetectionZone
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

@onready var hitbox: Area2D = $Hitbox
@onready var hitbox_shape: CollisionShape2D = $Hitbox/CollisionShape2D
@onready var hurtbox: Area2D = $Hurtbox

var _player: Node2D = null
var _home_pos: Vector2
var _attack_cd_left: float = 0.0
var _dead: bool = false
var _knockback_vel: Vector2 = Vector2.ZERO

func _ready() -> void:
	_home_pos = global_position

	# Выключим хитбокс по умолчанию
	hitbox_shape.disabled = true
	update_boxes_side()

	# Подключим damaged от Hurtbox
	if not hurtbox.damaged.is_connected(_on_damaged):
		hurtbox.damaged.connect(_on_damaged)

	# DetectionZone
	if not detection_zone.body_entered.is_connected(_on_detection_zone_body_entered):
		detection_zone.body_entered.connect(_on_detection_zone_body_entered)
	if not detection_zone.body_exited.is_connected(_on_detection_zone_body_exited):
		detection_zone.body_exited.connect(_on_detection_zone_body_exited)

func _physics_process(delta: float) -> void:
	if _dead:
		return
	
	_attack_cd_left = maxf(0.0, _attack_cd_left - delta)

	# Если игрок пропал/удалён
	if _player != null and not is_instance_valid(_player):
		_player = null

	# Считаем желаемое движение
	var desired_vel := Vector2.ZERO
	if _player:
		desired_vel = _get_chase_velocity()
	else:
		desired_vel = _get_return_velocity()

	# Применяем движение + отбрасывание
	velocity = desired_vel + _knockback_vel
	move_and_slide()

	# Затухание импульса
	_knockback_vel = _knockback_vel.move_toward(Vector2.ZERO, knockback_damp * delta)

func _get_chase_velocity() -> Vector2:
	var to_player := _player.global_position - global_position
	var dist := to_player.length()

	# Flip к игроку
	if absf(to_player.x) > 0.001:
		var new_flip := to_player.x < 0.0
		if sprite.flip_h != new_flip:
			sprite.flip_h = new_flip
			update_boxes_side()

	# Если близко — атакуем (по кулдауну)
	if dist <= attack_distance and _attack_cd_left <= 0.0:
		_attack_cd_left = attack_cooldown
		attack()

		# (опционально) визуал атаки
		if sprite.has_method("attack_visual"):
			sprite.attack_visual()

	# Движение к игроку
	return to_player.normalized() * move_speed if dist > 0.001 else Vector2.ZERO

func _get_return_velocity() -> Vector2:
	var to_home := _home_pos - global_position
	var dist := to_home.length()

	if dist <= return_stop_distance:
		global_position = _home_pos
		return Vector2.ZERO

	# Flip по направлению домой (не обязательно, но ок)
	if absf(to_home.x) > 0.001:
		var new_flip := to_home.x < 0.0
		if sprite.flip_h != new_flip:
			sprite.flip_h = new_flip
			update_boxes_side()

	return to_home.normalized() * move_speed

func update_boxes_side() -> void:
	var x := -6.0 if sprite.flip_h else 6.0
	hitbox.position.x = x

func _on_damaged(amount: int, attacker: Node2D) -> void:
	if _dead:
		return

	hp -= amount
	if hp <= 0:
		hp = 0
		die()
		return

	# отбрасывание
	var dir := Vector2.ZERO
	if attacker != null and is_instance_valid(attacker):
		dir = (global_position - attacker.global_position).normalized()
	else:
		dir = Vector2.RIGHT if sprite.flip_h else Vector2.LEFT

	_knockback_vel = dir * knockback_strength

func die() -> void:
	if _dead:
		return
	_dead = true
	_player = null

	velocity = Vector2.ZERO
	_knockback_vel = Vector2.ZERO

	# Defer ALL physics toggles (called during area signals)
	_disable_collisions_deferred.call_deferred()

	# death animation
	if sprite.sprite_frames and sprite.sprite_frames.has_animation("death"):
		sprite.play("death")
		await sprite.animation_finished

	Effects.spawn_death_effect(get_tree().current_scene, global_position, global_rotation)
	queue_free()


func _disable_collisions_deferred() -> void:
	# hitbox shape
	if is_instance_valid(hitbox_shape):
		hitbox_shape.set_deferred("disabled", true)

	# detection zone
	if is_instance_valid(detection_zone):
		detection_zone.set_deferred("monitoring", false)
		detection_zone.set_deferred("monitorable", false)

	# (optional) also disable hurtbox so it can’t be damaged again
	if is_instance_valid(hurtbox):
		hurtbox.set_deferred("monitoring", false)
		hurtbox.set_deferred("monitorable", false)

	# body collision
	set_deferred("collision_layer", 0)
	set_deferred("collision_mask", 0)

func attack() -> void:
	if _dead:
		return
	hitbox_shape.set_deferred("disabled", false)
	await get_tree().create_timer(0.2).timeout
	if is_instance_valid(hitbox_shape):
		hitbox_shape.set_deferred("disabled", true)


func _on_detection_zone_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		_player = body as Node2D

func _on_detection_zone_body_exited(body: Node) -> void:
	if body == _player:
		_player = null
