extends Area2D

signal damaged(amount: int, attacker: Node2D)

func take_damage(amount: int, attacker: Node2D = null) -> void:
	emit_signal("damaged", amount, attacker)
