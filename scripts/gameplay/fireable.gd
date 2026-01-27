extends Node
class_name Fireable

## Emitted the moment a fire attempt successfully starts.
signal fired(user: Node)

## Emitted when firing finishes (immediate by default; later can be animation/cooldown driven).
signal fire_complete

@export_group("Fireable")
@export var is_fireable: bool = true

## NOTE: This is intended to be runtime state (treat it as read-only in the inspector).
@export var is_fired: bool = false

@export_group("Timing")
## If 0, fire completes immediately. If > 0, fire_complete emits after this delay.
@export_range(0.0, 10.0, 0.01) var fire_duration: float = 0.0

## Optional extra lockout after firing completes (room for cooldown mechanics).
@export_range(0.0, 10.0, 0.01) var cooldown: float = 0.0

var _cooldown_until_msec: int = 0

func can_fire() -> bool:
	if not is_fireable:
		return false
	if is_fired:
		return false
	if Time.get_ticks_msec() < _cooldown_until_msec:
		return false
	return true


func fire(user: Node = null) -> bool:
	# This is what your Player calls on Left Click, IF the item is held.
	if not can_fire():
		return false

	is_fired = true
	fired.emit(user)

	# Finish immediately, or after a duration (for animation/cooldown hooks later).
	if fire_duration <= 0.0:
		_finish_fire()
	else:
		# Non-blocking: we schedule completion without forcing the caller to await.
		get_tree().create_timer(fire_duration).timeout.connect(_finish_fire, CONNECT_ONE_SHOT)

	return true


func _finish_fire() -> void:
	is_fired = false

	if cooldown > 0.0:
		_cooldown_until_msec = Time.get_ticks_msec() + int(cooldown * 1000.0)

	fire_complete.emit()
