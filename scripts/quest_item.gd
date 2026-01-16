extends Node2D
class_name QuestItem

@export var quest: QuestResource
@export var goal: QuestGoalResource
@export var amount: int = 1

@export var only_if_active_matches: bool = true

@export var bob_enabled: bool = true
@export var bob_amplitude: float = 6.0
@export var bob_period: float = 1.2

@export var pickup_fx_scene: PackedScene

@onready var pickup_area: Area2D = $PickupArea

var _picked := false
var _parent2d: Node2D
var _base_parent_pos: Vector2

func _ready() -> void:
	_parent2d = get_parent() as Node2D
	if _parent2d == null:
		push_error("QuestItem должен быть ребёнком Node2D (родитель будет удаляться).")
		return

	# Если квест уже сдан — предмет не нужен
	if quest != null and GM.has_completed(quest.id):
		_parent2d.call_deferred("queue_free")
		return

	_base_parent_pos = _parent2d.position

	if not pickup_area.body_entered.is_connected(_on_body_entered):
		pickup_area.body_entered.connect(_on_body_entered)

	# Чтобы предмет исчез сразу после сдачи квеста (без перезагрузки сцены)
	GM.quest_completed.connect(_on_any_quest_completed)

	if bob_enabled:
		_start_bob_parent()

func _exit_tree() -> void:
	# аккуратно отключаемся (не обязательно, но полезно)
	if GM != null and GM.quest_completed.is_connected(_on_any_quest_completed):
		GM.quest_completed.disconnect(_on_any_quest_completed)

func _on_any_quest_completed(quest_id: String) -> void:
	if _picked:
		return
	if quest == null:
		return

	# quest.id у тебя StringName, а сигнал может быть String
	if String(quest.id) == quest_id:
		_parent2d.call_deferred("queue_free")

func _start_bob_parent() -> void:
	var t := create_tween()
	t.set_loops()
	t.tween_property(_parent2d, "position:y", _base_parent_pos.y - bob_amplitude, bob_period * 0.5)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	t.tween_property(_parent2d, "position:y", _base_parent_pos.y + bob_amplitude, bob_period * 0.5)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _on_body_entered(body: Node) -> void:
	if _picked:
		return
	if not body.is_in_group("player"):
		return

	# Если квест уже сдан — просто убираем предмет (без FX)
	if quest != null and GM.has_completed(quest.id):
		_picked = true
		pickup_area.set_deferred("monitoring", false)
		pickup_area.set_deferred("monitorable", false)
		_parent2d.call_deferred("queue_free")
		return

	_picked = true

	pickup_area.set_deferred("monitoring", false)
	pickup_area.set_deferred("monitorable", false)

	_apply_quest_progress()
	_spawn_pickup_fx()

	_parent2d.call_deferred("queue_free")

func _apply_quest_progress() -> void:
	if quest == null or goal == null:
		return
	if goal.key == &"":
		return

	if only_if_active_matches:
		if GM.active_quest == null:
			return
		if GM.active_quest.id != quest.id:
			return

	GM.report_event(goal.key, max(amount, 1))

func _spawn_pickup_fx() -> void:
	if pickup_fx_scene == null:
		return
	var fx := pickup_fx_scene.instantiate()
	if fx is Node2D:
		(fx as Node2D).global_position = _parent2d.global_position
	get_tree().current_scene.add_child(fx)
