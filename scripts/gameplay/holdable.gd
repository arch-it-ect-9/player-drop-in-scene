extends Node
class_name Holdable

signal held(user: Node)
signal released(user: Node)

@export_group("Holdable")
@export var is_holdable: bool = true
@export var is_held: bool = false # runtime state (treat as read-only)

@export_group("Held Transform Tweaks")
# Local offset/rotation relative to the player's hold socket.
@export var hold_offset: Vector3 = Vector3.ZERO
@export var hold_rotation_degrees: Vector3 = Vector3.ZERO

@export_group("Behavior While Held")
@export var freeze_while_held: bool = true
@export var disable_collisions_while_held: bool = true

var _saved_layer: int = 0
var _saved_mask: int = 0


func get_body() -> RigidBody3D:
	# Expect this component to be a child of the item root.
	return get_parent() as RigidBody3D


func can_hold() -> bool:
	return is_holdable and not is_held


func on_held(user: Node) -> void:
	is_held = true
	var body := get_body()
	if body:
		if disable_collisions_while_held:
			_saved_layer = body.collision_layer
			_saved_mask = body.collision_mask
			body.collision_layer = 0
			body.collision_mask = 0
		if freeze_while_held:
			body.freeze = true
	held.emit(user)


func on_released(user: Node) -> void:
	is_held = false
	var body := get_body()
	if body:
		if disable_collisions_while_held:
			body.collision_layer = _saved_layer
			body.collision_mask = _saved_mask
		if freeze_while_held:
			body.freeze = false
	released.emit(user)
