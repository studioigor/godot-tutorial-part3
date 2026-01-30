# HealthBar.gd
extends ProgressBar

@export var tween_time: float = 0.18
@export var hide_delay: float = 2.0

var _owner: Node = null
var _hide_timer: Timer
var _tween: Tween

func _ready() -> void:
	_owner = get_parent()

	# По умолчанию скрыта
	visible = false

	# Таймер для автоскрытия
	_hide_timer = Timer.new()
	_hide_timer.one_shot = true
	_hide_timer.wait_time = hide_delay
	add_child(_hide_timer)
	_hide_timer.timeout.connect(_hide)

	# Берём max_value из "здоровья" родителя
	# 1) если есть max_hp / hp_max — используем
	# 2) иначе берём текущее hp как максимум (частый вариант для простых врагов)
	var max_hp := _get_max_hp()
	max_value = float(max_hp)

	# Текущее значение
	value = float(_get_hp())

	# Подписка на урон: ожидаем, что у родителя есть нода Hurtbox с сигналом damaged
	var hurtbox := _owner.get_node_or_null("Hurtbox")
	if hurtbox != null and hurtbox.has_signal("damaged"):
		hurtbox.damaged.connect(_on_damaged)

	# (опционально) если у родителя есть свой сигнал hp_changed(new_hp), тоже поддержим
	if _owner.has_signal("hp_changed"):
		_owner.hp_changed.connect(_on_hp_changed)

func _on_damaged(_amount: int, _attacker: Node2D) -> void:
	_show_and_update()

func _on_hp_changed(_new_hp: int) -> void:
	_show_and_update()

func _show_and_update() -> void:
	visible = true

	# Перезапускаем таймер скрытия (каждый новый удар продлевает показ)
	_hide_timer.start()

	# Плавно обновляем value
	var target := clampf(float(_get_hp()), 0.0, max_value)

	if _tween != null and _tween.is_valid():
		_tween.kill()

	_tween = create_tween()
	_tween.tween_property(self, "value", target, tween_time)

func _hide() -> void:
	visible = false

func _get_hp() -> int:
	# Поддержим разные названия
	if "hp" in _owner:
		return int(_owner.hp)
	if "health" in _owner:
		return int(_owner.health)
	return int(max_value)

func _get_max_hp() -> int:
	if "max_hp" in _owner:
		return int(_owner.max_hp)
	if "hp_max" in _owner:
		return int(_owner.hp_max)
	if "max_health" in _owner:
		return int(_owner.max_health)
	# Фолбек: текущий hp считаем максимумом
	return max(_get_hp(), 1)
