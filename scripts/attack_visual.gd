extends AnimatedSprite2D

var _attack_tween: Tween

func attack_visual() -> void:
	# Если анимация уже проигрывается — остановим предыдущий tween,
	# чтобы не накапливались и не конфликтовали изменения scale.
	if _attack_tween and _attack_tween.is_valid():
		_attack_tween.kill()

	# Настройки "на вкус"
	var prep_scale := Vector2(1.25, 0.75)   # растянуть X, сжать Y (подготовка)
	var hit_scale  := Vector2(1.10, 1.10)   # небольшой "панч" на ударе
	var prep_time := 0.07
	var hit_time  := 0.05
	var return_time := 0.14

	_attack_tween = create_tween()
	_attack_tween.set_parallel(false)

	# 1) Подготовка: резкий squash/stretch
	_attack_tween.tween_property(self, "scale", prep_scale, prep_time) \
		.set_trans(Tween.TRANS_BACK) \
		.set_ease(Tween.EASE_OUT)

	# 2) Удар: резко в норму + чуть увеличить (панч)
	# Для "резкости" можно сделать TRANS_LINEAR или TRANS_SINE, но с EASE_OUT.
	_attack_tween.tween_property(self, "scale", hit_scale, hit_time) \
		.set_trans(Tween.TRANS_LINEAR) \
		.set_ease(Tween.EASE_OUT)

	# 3) Возврат: плавно к (1, 1)
	_attack_tween.tween_property(self, "scale", Vector2.ONE, return_time) \
		.set_trans(Tween.TRANS_SINE) \
		.set_ease(Tween.EASE_OUT)
