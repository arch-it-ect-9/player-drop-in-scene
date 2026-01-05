extends CharacterBody3D

@export_category("Movement")
@export var walk_speed := 5.0
@export var sprint_speed := 8.5
@export var ground_accel := 14.0
@export var air_accel := 4.0
@export var jump_velocity := 4.8

# IMPORTANT: NodePaths are relative to this Player node (do NOT start with "Player/").
@export var right_hand_socket_path: NodePath = NodePath("Visuals/TacoTruckCookVisual/Model/TacoTruckCook_Rig/Skeleton3D/BoneAttachment3D")
@onready var right_hand_socket: Node3D = null

@export_category("Viewmodel")
@export var force_hand_visible_when_holding := true

const _RIGHT_HAND_SOCKET_FALLBACK_PATH := NodePath("Visuals/TacoTruckCookVisual/Model/TacoTruckCook_Rig/Skeleton3D/BoneAttachment3D")
const _MODEL_ROOT_PATH := NodePath("Visuals/TacoTruckCookVisual/Model")

# Cache of original surface materials so we can temporarily force "no depth test"
# when holding (so the raised hand doesn't get occluded by the body).
# Key: "<mesh_instance_id>:<surface_idx>" -> Material (can be null)
var _saved_surface_materials: Dictionary = {}

@export_category("Look")
@export var mouse_sensitivity := 0.0022
@export_range(0.0, 89.9, 0.1) var max_pitch_degrees := 89.0

@export_category("Interaction")
@export var interact_range := 3.0
@export var hold_lerp_speed := 12.0
@export var hold_snap_distance := 0.08

@export_category("Drop")
@export var drop_forward_velocity := 2.2
@export var drop_up_velocity := 1.5
@export var drop_gravity_scale := 0.6

@export_category("Animation")
@export var anim_tree_path: NodePath
@export var debug_anim := false

@onready var head: Node3D = $Head
@onready var camera: Camera3D = $Head/Camera3D
@onready var interact_ray: RayCast3D = $Head/InteractRay
@onready var hold_point: Marker3D = $Head/HoldPoint
@onready var hud: CanvasLayer = $HUD
@onready var crosshair: Control = $HUD/Crosshair

@onready var anim_tree: AnimationTree = get_node_or_null(anim_tree_path) as AnimationTree
var anim_playback: AnimationNodeStateMachinePlayback = null
var _warned_anim_playback_missing := false
var _was_holding := false

var held_item: PickupCube = null
var _held_snapped := false

var _gravity := 9.8
var _pitch_rad := 0.0
var _max_pitch_rad: float

const _DEBUG_SPIKE_DELTA_SEC := 0.050
const _DEBUG_SPIKE_COST_USEC := 20000
var _debug_last_spike_log_msec := 0


func _ready() -> void:
	_gravity = float(ProjectSettings.get_setting("physics/3d/default_gravity"))
	_max_pitch_rad = deg_to_rad(max_pitch_degrees)
	interact_ray.target_position = Vector3(0, 0, -interact_range)
	interact_ray.enabled = true
	print_debug("[Player] _ready() gravity=%s max_pitch_deg=%s range=%s" % [_gravity, max_pitch_degrees, interact_range]) # debug

	# AnimationTree wiring (optional; fail gracefully if missing)
	if anim_tree == null:
		push_warning("[Player] anim_tree_path not set or invalid.")
	else:
		anim_tree.active = true
		print("[Player] anim_tree.tree_root -> ", anim_tree.tree_root)

		anim_playback = anim_tree.get("parameters/playback") as AnimationNodeStateMachinePlayback
		if anim_playback == null:
			push_warning("[Player] anim_playback is null. Tree Root may not be StateMachine or tree not configured.")
		else:
			print("[Player] anim_playback current -> ", anim_playback.get_current_node())

	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	camera.current = true
	print_debug("[Player] mouse captured; camera.current=%s" % [camera.current]) # debug

	# Ensure initial state is consistent (guarded; will no-op if anim not wired)
	_set_character_hold_state(false, true)

	# Resolve the hand socket (BoneAttachment3D) now that the scene is ready.
	_resolve_right_hand_socket()


func _set_character_hold_state(is_holding: bool, force: bool = false) -> void:
	if (not force) and is_holding == _was_holding:
		return
	_was_holding = is_holding

	if anim_playback == null:
		if not _warned_anim_playback_missing:
			_warned_anim_playback_missing = true
			push_warning("[Player] _set_character_hold_state called but anim_playback is null")
		return

	var state_name := "Hold" if is_holding else "Idle"
	print("[Player] ANIM travel request -> ", state_name, " (held_item=", held_item, ")")
	if debug_anim:
		print("ANIM travel -> %s" % state_name)
	anim_playback.travel(state_name)
	print("[Player] ANIM current after travel -> ", anim_playback.get_current_node())


func _unhandled_input(event: InputEvent) -> void:
	# Toggle mouse capture (Esc)
	if event.is_action_pressed("ui_cancel"):
		print_debug("[Player] ui_cancel pressed; toggling mouse capture") # debug
		_toggle_mouse_capture()
		return

	# Temporary manual animation override (debug)
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_H:
			_set_character_hold_state(true, true)
		if event.keycode == KEY_J:
			_set_character_hold_state(false, true)

	# Interact (E) - pick up if possible
	if event.is_action_pressed("interact"):
		_try_pickup()

	# Drop (Q)
	if event.is_action_pressed("drop_item"):
		_drop_item()

	# Melee (Left click)
	if event.is_action_pressed("fire"):
		_try_melee()

	# Look
	if event is InputEventMouseMotion:
		# Body yaw
		rotate_y(-event.relative.x * mouse_sensitivity)

		# Head pitch
		_pitch_rad = clamp(
			_pitch_rad - event.relative.y * mouse_sensitivity,
			-_max_pitch_rad,
			_max_pitch_rad
		)
		head.rotation.x = _pitch_rad


func _physics_process(delta: float) -> void:
	var _frame_start_usec := Time.get_ticks_usec() # debug
	var on_floor := is_on_floor()

	# Timers / etc...
	var _after_timers_usec := Time.get_ticks_usec() # debug

	# Gravity
	if not on_floor:
		velocity.y -= _gravity * delta
	var _after_gravity_usec := Time.get_ticks_usec() # debug

	# Jump
	if Input.is_action_just_pressed("jump") and on_floor:
		velocity.y = jump_velocity
	var _after_jump_usec := Time.get_ticks_usec() # debug

	# Movement (relative to facing direction)
	var input_vec := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var local_dir := Vector3(input_vec.x, 0.0, input_vec.y)
	var wish_dir := (global_transform.basis * local_dir).normalized()

	var speed := sprint_speed if Input.is_action_pressed("sprint") else walk_speed
	var target := wish_dir * speed

	var accel := ground_accel if on_floor else air_accel
	velocity.x = move_toward(velocity.x, target.x, accel * delta)
	velocity.z = move_toward(velocity.z, target.z, accel * delta)
	var _after_move_math_usec := Time.get_ticks_usec() # debug

	var _move_and_slide_start_usec := Time.get_ticks_usec() # debug
	move_and_slide()
	var _after_move_and_slide_usec := Time.get_ticks_usec() # debug

	# If we have a held item that wasn't snapped into the hold point yet,
	# smoothly move it toward the target and finalize when close.
	if held_item != null and not _held_snapped:
		var t: float = clampf(hold_lerp_speed * delta, 0.0, 1.0)
		var curr_xform: Transform3D = Transform3D(held_item.global_transform.basis, held_item.global_transform.origin)

		var target_node: Node3D = _get_hold_target()
		var target_xform: Transform3D = Transform3D(target_node.global_transform.basis, target_node.global_transform.origin)

		# Position lerp
		curr_xform.origin = curr_xform.origin.lerp(target_xform.origin, t)
		# Rotation slerp using Basis.slerp
		curr_xform.basis = curr_xform.basis.slerp(target_xform.basis, t)
		held_item.global_transform = curr_xform

		# Finalize (snap/reparent) when close enough
		if curr_xform.origin.distance_to(target_xform.origin) <= hold_snap_distance:
			if right_hand_socket:
				held_item.reparent(right_hand_socket)
				held_item.transform = Transform3D.IDENTITY
			else:
				push_warning("[Player] RightHandSocket not found. Keeping current parent as fallback.")
			_held_snapped = true
			# Trigger Hold only once pickup is finalized (snapped into hand)
			_set_character_hold_state(true)
			_set_hand_visibility_override(true)

	# Debug spike logging (kept as-is)
	if delta >= _DEBUG_SPIKE_DELTA_SEC or (_after_move_and_slide_usec - _frame_start_usec) >= _DEBUG_SPIKE_COST_USEC:
		var now_msec := Time.get_ticks_msec()
		if now_msec - _debug_last_spike_log_msec >= 250:
			_debug_last_spike_log_msec = now_msec
			var total_usec := _after_move_and_slide_usec - _frame_start_usec
			var timers_usec := _after_timers_usec - _frame_start_usec
			var gravity_usec := _after_gravity_usec - _after_timers_usec
			var jump_usec := _after_jump_usec - _after_gravity_usec
			var move_math_usec := _after_move_math_usec - _after_jump_usec
			var move_and_slide_usec := _after_move_and_slide_usec - _move_and_slide_start_usec
			print_debug(
				"[Player] FRAME SPIKE delta=%.3fms fps=%s total=%dus timers=%dus gravity=%dus jump=%dus move_math=%dus move_and_slide=%dus pos=%s vel=%s" %
				[delta * 1000.0, Engine.get_frames_per_second(), total_usec, timers_usec, gravity_usec, jump_usec, move_math_usec, move_and_slide_usec, global_position, velocity]
			) # debug


func _toggle_mouse_capture() -> void:
	var captured := Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE if captured else Input.MOUSE_MODE_CAPTURED)
	crosshair.visible = not captured
	print_debug("[Player] mouse mode now: %s" % [Input.get_mouse_mode()]) # debug


func _resolve_right_hand_socket() -> void:
	# The exported NodePath is relative to this Player node.
	# In your project, the correct relative path is:
	#   Visuals/TacoTruckCookVisual/Model/TacoTruckCook_Rig/Skeleton3D/BoneAttachment3D
	var n: Node = get_node_or_null(right_hand_socket_path)
	if n == null:
		# If the inspector path is empty or wrong, fall back to the known-good rig path.
		right_hand_socket_path = _RIGHT_HAND_SOCKET_FALLBACK_PATH
		n = get_node_or_null(right_hand_socket_path)

	right_hand_socket = n as Node3D

	if right_hand_socket == null:
		push_warning("[Player] Right-hand socket not found. Check right_hand_socket_path (expected: %s)" % [String(_RIGHT_HAND_SOCKET_FALLBACK_PATH)])
	else:
		print_debug("[Player] Right-hand socket resolved -> %s" % [right_hand_socket.get_path()])


func _get_hold_target() -> Node3D:
	# Prefer the bone-attached socket (so the held item follows the hand).
	# Fall back to the camera hold point if something is misconfigured.
	return right_hand_socket if right_hand_socket != null else hold_point


func _set_hand_visibility_override(enabled: bool) -> void:
	# Makes the raised hand (and the rest of the mesh, if it's a single Skinned Mesh)
	# draw over itself by disabling depth test on materials.
	#
	# NOTE: If your character mesh is one combined skinned mesh, this will affect the whole body.
	# If your rig is split into multiple meshes, you can narrow this to only the right arm/hand mesh later.
	if not force_hand_visible_when_holding:
		return

	var model_root := get_node_or_null(_MODEL_ROOT_PATH)
	if model_root == null:
		return

	_apply_no_depth_test_recursive(model_root, enabled)


func _apply_no_depth_test_recursive(node: Node, enabled: bool) -> void:
	if node is MeshInstance3D:
		_apply_no_depth_test_to_mesh(node as MeshInstance3D, enabled)

	for child in node.get_children():
		_apply_no_depth_test_recursive(child, enabled)


func _apply_no_depth_test_to_mesh(mi: MeshInstance3D, enabled: bool) -> void:
	if mi.mesh == null:
		return

	var surface_count := mi.mesh.get_surface_count()
	for s in range(surface_count):
		var key := "%s:%s" % [mi.get_instance_id(), s]

		if enabled:
			# Save the current override (could be null) only once.
			if not _saved_surface_materials.has(key):
				_saved_surface_materials[key] = mi.get_surface_override_material(s)

			var base_mat := mi.get_active_material(s)
			if base_mat is BaseMaterial3D:
				var mat := (base_mat as BaseMaterial3D).duplicate() as BaseMaterial3D
				mat.no_depth_test = true
				# Draw late compared to default geometry.
				mat.render_priority = 127
				mi.set_surface_override_material(s, mat)
		else:
			if _saved_surface_materials.has(key):
				mi.set_surface_override_material(s, _saved_surface_materials[key])
				_saved_surface_materials.erase(key)


func _drop_item() -> void:
	if held_item == null:
		return

	# Parent to the current scene root (world)
	var drop_parent: Node = get_tree().get_current_scene() if get_tree().get_current_scene() != null else get_parent()
	var drop_transform: Transform3D = held_item.global_transform
	if right_hand_socket:
		drop_transform.origin = right_hand_socket.global_transform.origin

	# Call the pickup's drop helper which reparents and restores collisions/physics
	held_item.on_dropped(drop_parent, drop_transform)

	# Give it a light forward toss and lighter gravity so it falls gently
	var forward := -camera.global_transform.basis.z
	held_item.linear_velocity = forward * drop_forward_velocity + Vector3.UP * drop_up_velocity
	held_item.gravity_scale = drop_gravity_scale

	# Clear held state
	held_item = null
	_held_snapped = false
	_set_character_hold_state(false)
	_set_hand_visibility_override(false)


func _try_pickup() -> void:
	if held_item != null:
		return

	interact_ray.force_raycast_update()
	print("colliding=", interact_ray.is_colliding(), " collider=", interact_ray.get_collider())
	if not interact_ray.is_colliding():
		return

	var collider: Object = interact_ray.get_collider() as Object
	if collider is PickupCube:
		held_item = collider
		# Request pickup but don't snap immediately — we'll lerp it into place
		held_item.on_picked_up(_get_hold_target(), false)
		_held_snapped = false


func _try_melee() -> void:
	# Only melee if holding something
	if held_item == null:
		print_debug("[Player] _try_melee() ignored; not holding item") # debug
		return

	# (rest of your melee code unchanged...)
	var from := camera.global_transform.origin
	var to := from + (-camera.global_transform.basis.z) * 2.0

	var space := get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.exclude = [self, held_item]
	var result := space.intersect_ray(query)

	if result.is_empty():
		print_debug("[Player] _try_melee() no hit") # debug
		return

	var hit: Object = result.get("collider") as Object
	if hit == null:
		print_debug("[Player] _try_melee() hit collider null") # debug
		return
	print_debug("[Player] _try_melee() hit: %s" % [hit]) # debug

	if hit.has_method("apply_damage"):
		print_debug("[Player] applying damage=1 to %s" % [hit]) # debug
		hit.call("apply_damage", 1)
	else:
		print_debug("[Player] hit has no apply_damage(): %s" % [hit]) # debug
