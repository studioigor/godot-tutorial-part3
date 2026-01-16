extends Resource
class_name QuestResource

@export var id: StringName = &""
@export var title: String = ""
@export_multiline var description: String = ""
@export var goals: Array[QuestGoalResource] = []
