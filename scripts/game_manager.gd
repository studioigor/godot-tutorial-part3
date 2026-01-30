extends Node
class_name GameManager

# Сердца в "юнитах" (половинки): 0..max_hearts*2
signal lives_changed(new_lives: int)
signal hp_changed(current_hp: int, max_hp: int)
signal game_over

signal active_quest_changed(quest)
signal quest_completed(quest_id: String)
signal quest_progress_changed(quest_id: String)

@export var max_hearts: int = 3
@export var max_hp: int = 100 : set = set_max_hp
var current_hp: int = 100 : set = set_current_hp

var active_quest: QuestResource = null
var completed_quests: Array[String] = []
var active_progress: QuestProgress = null

# Текущее значение в "юнитах сердец" (0..max_hearts*2)
var lives: int = 0 : set = set_lives


func _ready() -> void:
	# На старте: полное здоровье
	current_hp = clampi(current_hp, 0, max_hp)
	_emit_all()


# -------------------------
# HP / LIVES CORE
# -------------------------

func set_max_hp(value: int) -> void:
	max_hp = maxi(value, 1)
	current_hp = clampi(current_hp, 0, max_hp)
	_sync_lives_from_hp()
	_emit_all()

func set_current_hp(value: int) -> void:
	current_hp = clampi(value, 0, max_hp)
	_sync_lives_from_hp()
	emit_signal("hp_changed", current_hp, max_hp)

	if current_hp <= 0:
		# lives тоже станет 0, но game_over отправим здесь гарантированно
		emit_signal("game_over")

func set_lives(value: int) -> void:
	# lives хранится как производная от hp, но setter оставим (на всякий)
	var max_units := max_hearts * 2
	lives = clampi(value, 0, max_units)
	emit_signal("lives_changed", lives)

func _sync_lives_from_hp() -> void:
	var max_units := max_hearts * 2
	var t := float(current_hp) / float(max_hp)  # 0..1
	var units_f := t * float(max_units)         # 0..max_units
	var units := clampi(int(round(units_f)), 0, max_units)
	lives = units
	emit_signal("lives_changed", lives)

func _emit_all() -> void:
	emit_signal("hp_changed", current_hp, max_hp)
	emit_signal("lives_changed", lives)

# Публичные методы для нанесения урона/лечения
func apply_damage(amount: int) -> void:
	if amount <= 0:
		return
	if current_hp <= 0:
		return
	set_current_hp(current_hp - amount)

func heal(amount: int) -> void:
	if amount <= 0:
		return
	if current_hp <= 0:
		return
	set_current_hp(current_hp + amount)

func set_full_health() -> void:
	set_current_hp(max_hp)


# -------------------------
# QUESTS (как было)
# -------------------------

func set_active_quest(quest: QuestResource) -> void:
	active_quest = quest
	active_progress = null

	if active_quest != null:
		active_progress = QuestProgress.new(active_quest)

	emit_signal("active_quest_changed", active_quest)

func has_completed(quest_id: String) -> bool:
	return completed_quests.has(quest_id)

func complete_active_quest() -> void:
	if active_quest == null:
		return

	if not completed_quests.has(active_quest.id):
		completed_quests.append(active_quest.id)

	emit_signal("quest_completed", active_quest.id)

	active_quest = null
	active_progress = null
	emit_signal("active_quest_changed", active_quest)

func report_event(event_key: StringName, amount: int = 1) -> void:
	if active_progress == null:
		return

	active_progress.apply_event(event_key, amount)

	if active_quest != null:
		emit_signal("quest_progress_changed", String(active_quest.id))

# -------------------------
# RESET
# -------------------------

func reset(keep_completed_quests: bool = false) -> void:
	# Сброс квестов
	active_quest = null
	active_progress = null
	emit_signal("active_quest_changed", active_quest)

	if not keep_completed_quests:
		completed_quests.clear()
		# Если у тебя UI/логика подписана на completed — можешь добавить отдельный сигнал, если нужен.

	# Сброс здоровья
	# ВАЖНО: сначала max_hp, потом current_hp, чтобы clamp/синк корректно отработали
	max_hp = maxi(max_hp, 1)
	set_current_hp(max_hp) # внутри синхронизирует lives и отправит hp_changed + lives_changed

	# На всякий случай (если где-то вручную менял lives)
	_sync_lives_from_hp()
	_emit_all()
