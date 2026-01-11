extends Area2D

@export_file("*.tscn") var target_level: String

var transitioning = false

func _on_body_entered(body):
	transitioning = true
	await transition_to_level()


func transition_to_level():
	var tree = get_tree()

	# Создаем ColorRect для fade эффекта
	var fade_rect = ColorRect.new()
	fade_rect.color = Color.BLACK
	fade_rect.color.a = 0.0
	fade_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	fade_rect.z_index = 100
	tree.root.add_child(fade_rect)

	# Fade out
	var tween = tree.create_tween()
	tween.tween_property(fade_rect, "color:a", 1.0, 0.5)
	await tween.finished

	# Переключаем уровень
	tree.change_scene_to_file(target_level)

	# Fade in
	await tree.process_frame
	tween = tree.create_tween()
	tween.tween_property(fade_rect, "color:a", 0.0, 0.5)
	await tween.finished

	fade_rect.queue_free()
