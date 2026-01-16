extends Node
class_name GameManager

signal lives_changed(new_lives: int)
signal active_quest_changed(quest)
signal quest_completed(quest_id: String)
signal quest_progress_changed(quest_id: String) # <-- добавили

@export var max_lives: int = 3
var lives: int = 3 : set = set_lives

var active_quest: QuestResource = null
var completed_quests: Array[String] = []
var active_progress: QuestProgress = null

func _ready() -> void:
	lives = max_lives

func set_lives(value: int) -> void:
	lives = clamp(value, 0, max_lives)
	emit_signal("lives_changed", lives)

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
