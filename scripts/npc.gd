extends Node2D
class_name NPCQuestGiver2D

@export var npc_name: String = "NPC"
@export var quest_to_give: QuestResource
@export var next_quest: QuestResource

@onready var marker: Label = $QuestMarker
@onready var canvasLayer: CanvasLayer = $CanvasLayer

var _player_in_range := false
var _ui_instance: Control = null

# флаг: квест только что сдан (чтобы панель показала благодарность)
var _just_turned_in := false

# --- маркер ---
var _marker_base_pos: Vector2
var _marker_tween: Tween

func _ready() -> void:
	$InteractArea.body_entered.connect(_on_body_entered)
	$InteractArea.body_exited.connect(_on_body_exited)

	_marker_base_pos = marker.position
	_setup_marker_tween()
	_update_marker()

	GM.active_quest_changed.connect(_update_marker)
	GM.quest_completed.connect(_update_marker)

func _unhandled_input(event: InputEvent) -> void:
	if not _player_in_range:
		return
	if event.is_action_pressed("ui_select"):
		# 1) пробуем сдать (без кнопки)
		_just_turned_in = try_turn_in_on_talk()
		# 2) открываем UI
		_open_npc_ui()

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		_player_in_range = true

func _on_body_exited(body: Node) -> void:
	if body.is_in_group("player"):
		_player_in_range = false
		_close_npc_ui()

func _open_npc_ui() -> void:
	if _ui_instance != null:
		_ui_instance.queue_free()

	var scene := preload("res://scenes/quest_panel.tscn")
	_ui_instance = scene.instantiate()
	canvasLayer.add_child(_ui_instance)
	_ui_instance.setup(self)

func _close_npc_ui() -> void:
	if _ui_instance != null:
		_ui_instance.queue_free()
		_ui_instance = null

# --- для панели: забрать флаг "только что сдано" ---
func consume_just_turned_in() -> bool:
	if _just_turned_in:
		_just_turned_in = false
		return true
	return false

# -------- Статусы --------

func get_state() -> String:
	if quest_to_give == null:
		return "nothing"

	# уже выполнен
	if GM.has_completed(quest_to_give.id):
		if next_quest != null and not GM.has_completed(next_quest.id) and GM.active_quest == null:
			return "offer_next"
		return "nothing"

	# этот квест активен
	if GM.active_quest != null and GM.active_quest.id == quest_to_give.id:
		if GM.active_progress != null and GM.active_progress.is_completed():
			return "turnin"
		return "in_progress"

	# другой квест активен
	if GM.active_quest != null:
		return "busy"

	return "offer"

func get_offer_quest() -> QuestResource:
	if get_state() == "offer_next":
		return next_quest
	return quest_to_give

func accept_quest() -> void:
	if GM.active_quest != null:
		return
	var q := get_offer_quest()
	if q == null:
		return
	GM.set_active_quest(q)

# (кнопкой не пользуемся, но пусть останется)
func turn_in() -> void:
	if GM.active_quest == null:
		return
	if GM.active_quest.id != quest_to_give.id:
		return
	if GM.active_progress == null or not GM.active_progress.is_completed():
		return
	GM.complete_active_quest()

func try_turn_in_on_talk() -> bool:
	if quest_to_give == null:
		return false
	if GM.active_quest == null:
		return false
	if GM.active_quest.id != quest_to_give.id:
		return false
	if GM.active_progress == null:
		return false
	if not GM.active_progress.is_completed():
		return false

	GM.complete_active_quest()
	return true

# -------- Маркер "!" --------

func _update_marker(_arg = null) -> void:
	var state := get_state()
	var can_give := (state == "offer" or state == "offer_next")
	marker.visible = can_give

	if not marker.visible:
		marker.position = _marker_base_pos

func _setup_marker_tween() -> void:
	var amplitude := 6.0
	var duration := 0.6

	if _marker_tween != null and _marker_tween.is_valid():
		_marker_tween.kill()

	_marker_tween = create_tween()
	_marker_tween.set_loops()

	_marker_tween.tween_property(
		marker, "position", _marker_base_pos + Vector2(0, -amplitude), duration
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	_marker_tween.tween_property(
		marker, "position", _marker_base_pos, duration
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
