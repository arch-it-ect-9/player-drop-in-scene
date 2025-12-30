extends CharacterBody3D

@export_category("Movement")
@export var walk_speed := 5.0
@export var sprint_speed := 8.5
@export var ground_accel := 14.0
@export var air_accel := 4.0
@export var jump_velocity := 4.8

@export var right_hand_socket_path: NodePath
@onready var right_hand_socket: Node3D = get_node_or_null(right_hand_socket_path) as Node3D

@export_category("Look")
@export var mouse_sensitivity := 0.0022
@export_range(0.0, 89.9, 0.1) var max_pitch_degrees := 89.0

@export_category("Interact")
@export var interact_range := 3.0
@export var melee_range := 3.5

@export_category("Hold")
@export var hold_lerp_speed := 12.0
@export var hold_snap_distance := 0.05
@export var drop_forward_velocity := 3.0
@export var drop_up_velocity := 0.5
@export var drop_gravity_scale := 0.9

@export_category("Combat")
@export var melee_cooldown := 1.0

@export_category("Animation")
@export var anim_tree_path: NodePath
@export var debug_anim: bool = false

@onready var head: Node3D = $Head
@onready var camera: Camera3D = $Head/Camera3D
@onready var interact_ray: RayCast3D = $Head/InteractRay
@onready var hold_point: Marker3D = $Head/HoldPoint
@onready var hud: CanvasLayer = $HUD
@onready var crosshair: Control = $HUD/Crosshair

@onready var anim_tree: AnimationTree = get_node_or_null(anim_tree_path) as AnimationTree
var anim_playback: AnimationNodeStateMachinePlayback = null


var held_item: PickupCube = null
var _held_snapped := false
var _melee_timer := 0.0

var _was_holding: bool = false
var _warned_anim_playback_missing: bool = false

var _gravity: float
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
	print_debug("[Player] _ready() gravity=%s max_pitch_deg=%s interact_range=%s" % [_gravity, max_pitch_degrees, interact_range]) # debug

	# AnimationTree wiring (optional; fail gracefully if missing)
	if anim_tree == null:
		push_warning("[Player] anim_tree is null. anim_tree_path not set or path invalid.")
	else:
		anim_tree.active = true
		print("[Player] anim_tree resolved -> ", anim_tree.get_path())
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

	if right_hand_socket == null:
		push_warning("[Player] right_hand_socket_path not assigned or invalid.")


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
			return
		if event.keycode == KEY_J:
			_set_character_hold_state(false, true)
			return

	# Ignore gameplay inputs if we don't have captured mouse
	if Input.get_mouse_mode() != Input.MOUSE_MODE_CAPTURED:
		return

	# Interact (E) - pick up if possible
	if event.is_action_pressed("interact"):
		print_debug("[Player] interact pressed") # debug
		_try_pickup()
		return

	# Fire (LMB) - melee only if holding item (cooldown handled in _try_melee)
	if event.is_action_pressed("fire"):
		print_debug("[Player] fire pressed") # debug
		_try_melee()
		return

	# Drop (Q)
	if event.is_action_pressed("drop_item"):
		print_debug("[Player] drop pressed") # debug
		_drop_item()
		return

	# Mouse look
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
	
	_melee_timer = maxf(_melee_timer - delta, 0.0)
	var _after_timers_usec := Time.get_ticks_usec() # debug

	# Gravity
	if not on_floor:
		velocity.y -= _gravity * delta
	elif velocity.y < 0.0:
		velocity.y = 0.0
	var _after_gravity_usec := Time.get_ticks_usec() # debug

	# Jump
	if on_floor and Input.is_action_just_pressed("jump"):
		print_debug("[Player] jump pressed; velocity.y=%s -> %s" % [velocity.y, jump_velocity]) # debug
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
	# smoothly move it toward the hold_point and finalize when close.
	if held_item != null and not _held_snapped:
		var t: float = clampf(hold_lerp_speed * delta, 0.0, 1.0)
		var curr_xform: Transform3D = Transform3D(held_item.global_transform.basis, held_item.global_transform.origin)
		var target_node: Node3D = right_hand_socket if right_hand_socket != null else hold_point
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

	# Log only when we detect a hitch.
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
		held_item.on_picked_up(hold_point, false)
		_held_snapped = false


func _try_melee() -> void:
	# Only melee if holding something
	if held_item == null:
		print_debug("[Player] _try_melee() ignored; not holding item") # debug
		return

	# 1 hit per 1 second
	if _melee_timer > 0.0:
		print_debug("[Player] _try_melee() on cooldown: %s" % [_melee_timer]) # debug
		return
	_melee_timer = melee_cooldown
	print_debug("[Player] _try_melee() started; cooldown reset to %s" % [melee_cooldown]) # debug

	# Simple melee “hit test”: short ray from camera forward
	var space: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state
	var from: Vector3 = camera.global_transform.origin
	var to: Vector3 = from + (-camera.global_transform.basis.z) * melee_range

	var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(from, to)
	query.exclude = [self, held_item]
	query.collide_with_areas = false
	# If you want to limit to certain layers later, set query.collision_mask

	var result: Dictionary = space.intersect_ray(query)
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
