extends Area2D

@export var u_damage: int = 10

func _ready() -> void:
	area_entered.connect(_on_area_entered)

func _on_area_entered(area: Area2D) -> void:
	if area != null and area.has_method("take_damage"):
		# Атакующий = родитель (персонаж), к которому прикреплена Hitbox
		area.take_damage(u_damage, get_parent() as Node2D)
