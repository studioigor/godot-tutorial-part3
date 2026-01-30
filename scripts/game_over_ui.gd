extends Panel

@export var retry_scene_path: String = "res://scenes/level_1.tscn"  # опционально: куда перезагружать

func _on_button_pressed():
	GM.reset()
	if retry_scene_path != "":
		get_tree().change_scene_to_file(retry_scene_path)
	else:
		get_tree().reload_current_scene()
