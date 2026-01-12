extends RigidBody3D
class_name PickupCube

@export var held_collision_disabled := true

var _default_collision_layer: int
var _default_collision_mask: int
var _default_gravity_scale: float
var _default_freeze: bool
var _defaults_captured := false

var _held_collision_overridden := false


func _ready() -> void:
	_capture_defaults()


func _capture_defaults() -> void:
	if _defaults_captured:
		return
	_default_collision_layer = collision_layer
	_default_collision_mask = collision_mask
	_default_gravity_scale = gravity_scale
	_default_freeze = freeze
	_defaults_captured = true


func _restore_defaults() -> void:
	if not _defaults_captured:
		_capture_defaults()
	collision_layer = _default_collision_layer
	collision_mask = _default_collision_mask
	gravity_scale = _default_gravity_scale
	freeze = _default_freeze

func on_picked_up(holder: Node3D, snap: bool = true) -> void:
	# Reset to known defaults so any prior drop tweaks don't stick across cycles.
	_restore_defaults()
	_held_collision_overridden = false

	# Stop physics
	freeze = true
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO

	# Optionally disable collisions while held (prevents jittering into the player)
	# IMPORTANT: this function may be called twice by the player (first with snap=false,
	# then later with snap=true). Without this guard, the second call would overwrite
	# the saved collision layer/mask with 0, and dropping would restore 0 -> no collisions.
	if held_collision_disabled and not _held_collision_overridden:
		collision_layer = 0
		collision_mask = 0
		_held_collision_overridden = true

	# If snap is requested, immediately reparent and snap to holder.
	# If snap is false, we leave the body in the world (but frozen) so
	# the caller can smoothly interpolate it into position before finalizing.
	if snap:
		reparent(holder, true)
		global_transform = holder.global_transform

func on_dropped(drop_parent: Node, drop_transform: Transform3D) -> void:
	# Put back in world
	reparent(drop_parent, true)
	global_transform = drop_transform

	# Restore physics/collisions back to the original scene defaults.
	_restore_defaults()
	_held_collision_overridden = false

	# Ensure it can simulate again after being held.
	freeze = false
