extends RefCounted
class_name QuestProgress

var quest: QuestResource
var progress: Dictionary = {} # StringName -> int

func _init(q: QuestResource) -> void:
	quest = q
	for g in quest.goals:
		if g != null and g.key != &"":
			progress[g.key] = 0

func apply_event(event_key: StringName, amount: int = 1) -> void:
	if quest == null:
		return
	if not progress.has(event_key):
		return
	var needed := get_needed(event_key)
	var current := int(progress[event_key])
	progress[event_key] = min(current + amount, needed)

func get_value(event_key: StringName) -> int:
	return int(progress.get(event_key, 0))

func get_needed(event_key: StringName) -> int:
	if quest == null:
		return 0
	for g in quest.goals:
		if g != null and g.key == event_key:
			return g.required
	return 0

func is_completed() -> bool:
	if quest == null:
		return false
	for g in quest.goals:
		if g == null or g.key == &"":
			continue
		if get_value(g.key) < g.required:
			return false
	return true
