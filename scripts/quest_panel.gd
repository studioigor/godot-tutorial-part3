extends Control
class_name NPCQuestPanel

var npc: NPCQuestGiver2D

@onready var name_label: Label = $VBoxContainer/NameLabel
@onready var title_label: Label = $VBoxContainer/TitleLabel
@onready var desc_label: RichTextLabel = $VBoxContainer/DescLabel
@onready var goals_box: VBoxContainer = $VBoxContainer/GoalsBox
@onready var accept_btn: Button = $VBoxContainer/HBoxContainer/AcceptButton
@onready var close_btn: Button = $VBoxContainer/HBoxContainer/CloseButton

func _ready() -> void:
	accept_btn.pressed.connect(_on_accept)
	close_btn.pressed.connect(queue_free)

	GM.active_quest_changed.connect(_refresh)
	GM.quest_completed.connect(_refresh)
	if GM.has_signal("quest_progress_changed"):
		GM.quest_progress_changed.connect(_on_progress_changed)

func setup(npc_ref) -> void:
	npc = npc_ref
	_refresh()

func _on_progress_changed(_quest_id: String) -> void:
	_refresh()

func _refresh(_arg = null) -> void:
	if npc == null:
		return

	name_label.text = npc.npc_name

	for c in goals_box.get_children():
		c.queue_free()

	accept_btn.visible = false

	# 1) Если квест только что был сдан при разговоре — показываем благодарность
	if npc.consume_just_turned_in():
		title_label.text = "Спасибо!"
		desc_label.text = "Отличная работа. Квест сдан."
		return

	# 2) Иначе показываем обычное состояние
	var state := npc.get_state()

	match state:
		"busy":
			title_label.text = "У тебя уже есть активный квест"
			desc_label.text = "Сначала заверши текущий квест."
		"in_progress":
			var q: QuestResource = GM.active_quest
			title_label.text = q.title
			desc_label.text = q.description
			_show_goals(q, true)
		"turnin":
			# квест выполнен, но ещё не сдан
			var q: QuestResource = GM.active_quest
			title_label.text = q.title
			desc_label.text = "Квест выполнен. Поговори со мной, чтобы сдать его."
			_show_goals(q, true)
		"offer", "offer_next":
			var q: QuestResource = npc.get_offer_quest()
			title_label.text = q.title
			desc_label.text = q.description
			_show_goals(q, false)
			accept_btn.visible = true
		"nothing":
			title_label.text = "Нечего предложить"
			desc_label.text = "Заданий пока нет."

func _show_goals(q: QuestResource, show_progress: bool) -> void:
	if q == null:
		return

	for g in q.goals:
		if g == null or g.key == &"":
			continue

		var needed := g.required
		var current := 0

		if show_progress \
		and GM.active_quest != null \
		and GM.active_quest.id == q.id \
		and GM.active_progress != null:
			current = GM.active_progress.get_value(g.key)

		var l := Label.new()
		if show_progress:
			l.text = "- %s: %d/%d" % [g.title, current, needed]
		else:
			l.text = "- %s: %d" % [g.title, needed]

		goals_box.add_child(l)

func _on_accept() -> void:
	if npc == null:
		return
	npc.accept_quest()
	_refresh()
