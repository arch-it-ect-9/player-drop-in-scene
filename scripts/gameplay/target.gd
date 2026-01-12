extends StaticBody3D
class_name TargetDummy

@export var max_hits := 10
var hits := 0

func apply_damage(amount: int) -> void:
	hits += amount
	if hits >= max_hits:
		queue_free()
