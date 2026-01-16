extends CanvasLayer
class_name QuestHUD

@onready var title_label: Label = $VBoxContainer/QuestTitle
@onready var goals_box: VBoxContainer = $VBoxContainer/GoalsBox

func _ready() -> void:
	GM.active_quest_changed.connect(_refresh)
	GM.quest_completed.connect(_refresh)
	if GM.has_signal("quest_progress_changed"):
		GM.quest_progress_changed.connect(_on_progress_changed)

	_refresh()

func _on_progress_changed(_quest_id: String) -> void:
	_refresh()

func _refresh(_arg = null) -> void:
	for c in goals_box.get_children():
		c.queue_free()

	if GM.active_quest == null:
		title_label.text = "Квест: нет"
		return

	var q: QuestResource = GM.active_quest
	title_label.text = "Квест: %s" % q.title

	if GM.active_progress == null:
		return

	# q.goals теперь Array[QuestGoalResource]
	for g in q.goals:
		if g == null or g.key == &"":
			continue

		var needed := g.required
		var current := GM.active_progress.get_value(g.key)

		var l := Label.new()
		l.text = "%s: %d/%d" % [g.title, current, needed]
		goals_box.add_child(l)
