# Player Drop-In Scene — Workspace Summary

**Date:** January 24, 2026  
**Engine:** Godot 4.5.1 (Forward Plus renderer)  
**Modeler/Asset Tool:** Blender 4.5  
**Project Name:** `Player_DropInScene`

---

## Project Overview

This is a first-person player controller template/drop-in scene for Godot 4.5. The project demonstrates a complete FPS character setup with separate viewmodel and worldmodel rendering, a generic object holding system, and a component-based interaction framework.

---

## Folder Structure with Scene Node Trees

```
player-drop-in-scene/
├── project.godot
├── icon.svg
│
├── assets/
│   ├── characters/
│   │   └── player/
│   │       ├── materials/                    # Shared texture imports (.png.import files)
│   │       │
│   │       ├── viewmodel/
│   │       │   ├── fps_viewmodel_arms.glb    # Blender binary export
│   │       │   ├── fps_viewmodel_arms.gltf   # Blender glTF export (bone/animation reference)
│   │       │   └── fps_viewmodel_arms.tscn   # uid://bdsr0tfgopm7
│   │       │       └── fps_viewmodel_arms (instance of .glb)
│   │       │           ├── Armature
│   │       │           │   └── Skeleton3D
│   │       │           │       └── fps_viewmodel_arms (MeshInstance3D, layers=2, cast_shadow=0)
│   │       │           └── AnimationPlayer (autoplay="idle_unarmed")
│   │       │
│   │       └── worldmodel/
│   │           ├── taco_truck_cook_world.glb # Blender binary export
│   │           ├── taco_truck_cook_world.gltf # Blender glTF export (bone/animation reference)
│   │           └── taco_truck_cook_world.tscn # uid://bordqsg5k5ij0
│   │               └── TacoTruckCookVisual (Node3D)
│   │                   ├── Model (instance of .glb)
│   │                   │   └── TacoTruckCook_Rig
│   │                   │       └── Skeleton3D
│   │                   │           └── BoneAttachment3D (bone_name="hand.R", bone_idx=5)
│   │                   └── AnimationTree (states: Start→Idle↔Hold)
│   │
│
├── scenes/
│   ├── actors/
│   │   └── player/
│   │       └── player.tscn                   # uid://b3gqjpq5gcrs1
│   │           └── Player (CharacterBody3D, script=player.gd)
│   │               ├── CollisionShape3D (CapsuleShape3D r=0.35 h=1.4, y=0.763)
│   │               ├── Head (Node3D, y=1.4, z=-0.186)
│   │               │   ├── WorldCamera (Camera3D, cull_mask=1, current=true)
│   │               │   │   └── HandTarget (Marker3D, x=0.219 y=-0.285 z=-0.417)
│   │               │   ├── InteractRay (RayCast3D, target=Vector3(0,0,-3), collision_mask=4)
│   │               │   └── HoldPoint (Marker3D, rotated, x=0.33 y=-0.135 z=-1.145)
│   │               ├── HUD (CanvasLayer)
│   │               │   ├── Crosshair (TextureRect, 16×16, centered)
│   │               │   │   └── ColorRect (4×4 white square)
│   │               │   ├── InteractPrompt (Label, centered, hidden when no target)
│   │               │   └── ViewModelViewportContainer (SubViewportContainer, stretch=true)
│   │               │       └── ViewModelViewport (SubViewport, transparent_bg=true)
│   │               │           └── ViewModelWorld (Node3D)
│   │               │               ├── ViewModelCamera_VM (Camera3D, cull_mask=2, fov=30)
│   │               │               └── ViewModelRoot_VM (Node3D, scale=-1.15, y=1.4, z=-0.326)
│   │               │                   └── fps_viewmodel_arms (instance, z=-0.1)
│   │               └── Visuals (Node3D)
│   │                   └── TacoTruckCookVisual (instance of taco_truck_cook_world.tscn)
│   │
│   ├── gameplay/
│   │   ├── target.tscn                       # uid://d1cw1gxmumlhg
│   │   │   └── Target (StaticBody3D, script=target.gd)
│   │   │       ├── CollisionShape3D (BoxShape3D)
│   │   │       └── MeshInstance3D (BoxMesh)
│   │   └── interactables/
│   │       └── button.tscn                   # uid://cg6iq61db0ftr
│   │           ├── Button (StaticBody3D, script=button.gd)
│   │           ├── MeshInstance3D (BoxMesh)
│   │           ├── CollisionShape3D (BoxShape3D)
│   │           └── Interactable (Node, script=interactable.gd, emits on use)
│   │
│   └── levels/
│       └── test_level.tscn                   # uid://e3fdy8h24p5 (main_scene)
│           └── TestLevel (Node3D)
│               ├── DirectionalLight3D
│               ├── WorldEnvironment (procedural sky)
│               ├── Floor (StaticBody3D, y=-0.5)
│               │   ├── CollisionShape3D (BoxShape3D 50×1×50)
│               │   └── MeshInstance3D (BoxMesh 50×1×50)
│               ├── Player (instance of player.tscn)
│               ├── Target (instance of target.tscn, z=-10.825)
│               └── Button (instance of button.tscn, y=1.426, z=-3.25)
│
└── scripts/
    ├── gameplay/
    │   ├── interactable.gd                   # class_name Interactable
    │   ├── holdable.gd                       # class_name Holdable
    │   ├── fireable.gd                       # class_name Fireable
    │   ├── target.gd                         # class_name TargetDummy
    │   └── interactables/
    │       └── button.gd
    └── player/
        └── player.gd                         # Player controller
```

### Node Path Reference Quick Guide

From `player.gd` (attached to Player node):
| Node | Path from Player |
|------|------------------|
| Head | `$Head` |
| WorldCamera | `$Head/WorldCamera` |
| HandTarget | `$Head/WorldCamera/HandTarget` |
| InteractRay | `$Head/InteractRay` |
| HoldPoint | `$Head/HoldPoint` |
| InteractPrompt | `$HUD/InteractPrompt` |
| Crosshair | `$HUD/Crosshair` |
| ViewModelViewport | `$HUD/ViewModelViewportContainer/ViewModelViewport` |
| ViewModelCamera_VM | `$HUD/ViewModelViewportContainer/ViewModelViewport/ViewModelWorld/ViewModelCamera_VM` |
| ViewModelRoot_VM | `$HUD/ViewModelViewportContainer/ViewModelViewport/ViewModelWorld/ViewModelRoot_VM` |
| fps_viewmodel_arms | `$HUD/ViewModelViewportContainer/ViewModelViewport/ViewModelWorld/ViewModelRoot_VM/fps_viewmodel_arms` |
| TacoTruckCookVisual | `$Visuals/TacoTruckCookVisual` |
| AnimationTree (worldmodel) | `$Visuals/TacoTruckCookVisual/AnimationTree` |

---

## Input Map

| Action        | Key/Button         | Purpose |
|---------------|--------------------|---------|
| `move_forward`| W                  | Move forward |
| `move_back`   | S                  | Move backward |
| `move_left`   | A                  | Strafe left |
| `move_right`  | D                  | Strafe right |
| `jump`        | Space              | Jump |
| `sprint`      | Shift              | Sprint |
| `interact`    | E                  | Interact with objects (via Interactable component) |
| `fire`        | Left Mouse Button  | Attack / use held item |
| `alt_fire`    | Right Mouse Button | Throw held item |
| `drop_item`   | Q                  | Drop held item |

---

## Scenes

### `scenes/levels/test_level.tscn`
The main scene and entry point. Contains:
- **WorldEnvironment** with procedural sky
- **DirectionalLight3D** for scene lighting
- **Floor** — 50×50 unit StaticBody3D platform
- **Player** — instanced player scene
- **Target** — target dummy at position (0.06, 0, -10.825)
- **Button** — interactable test block at position (0, 1.426, -3.25)

### `scenes/actors/player/player.tscn`
First-person CharacterBody3D player with:
- **CollisionShape3D** — Capsule (radius 0.35, height 1.4)
- **Head** (Node3D at y=1.4)
  - **WorldCamera** — Main camera, cull_mask=1 (excludes viewmodel layer)
  - **HandTarget** — Marker3D for hand IK positioning
  - **InteractRay** — RayCast3D, 3m range, collision_mask=4 (interactables layer)
  - **HoldPoint** — Marker3D for held object placement (rotated for natural hold pose)
- **HUD** (CanvasLayer)
  - **Crosshair** — Centered 16×16 white square
  - **InteractPrompt** — Centered label that shows nearby interactable prompts
  - **ViewModelViewportContainer** → **ViewModelViewport** (SubViewport)
    - Separate rendering layer for first-person arms
    - **ViewModelCamera_VM** — cull_mask=2, FOV=30°
    - **ViewModelRoot_VM** → **fps_viewmodel_arms** instance
- **Visuals** → **TacoTruckCookVisual** — Third-person world model (for multiplayer/mirrors)

### `scenes/gameplay/interactables/button.tscn`
Simple interactable test block:
- StaticBody3D with BoxMesh and BoxShape3D
- `Interactable` component (interaction type: USE) connected to `_on_interactable_interacted`
- `button.gd` prints the user name when interacted with

### `scenes/gameplay/target.tscn`
Simple target dummy (StaticBody3D) with:
- BoxShape3D collision
- BoxMesh visual
- `target.gd` script attached

---

## Assets

### `assets/characters/player/viewmodel/fps_viewmodel_arms.tscn`
First-person arm model imported from Blender (`fps_viewmodel_arms.glb`). Features:
- Render layer 2 (viewmodel-only layer)
- Shadow casting disabled (`cast_shadow = 0`)
- Skeleton with bone pose adjustments for FPS positioning
- Autoplay animation: `idle_unarmed`

#### Viewmodel glTF Reference (`fps_viewmodel_arms.gltf`)

| Property | Value |
|----------|-------|
| Generator | Khronos glTF Blender I/O v4.5.49 |
| glTF Version | 2.0 |
| Binary Data | `fps_viewmodel_arms_data.bin` (64,288 bytes) |

**Skeleton Bone List (7 bones):**

| Index | Bone Name | Parent | Description |
|-------|-----------|--------|-------------|
| 0 | `upper_arm.L` | (root) | Left upper arm |
| 1 | `forearm.L` | `upper_arm.L` | Left forearm |
| 2 | `hand.L` | `forearm.L` | Left hand |
| 3 | `upper_arm.R` | (root) | Right upper arm |
| 4 | `forearm.R` | `upper_arm.R` | Right forearm |
| 5 | `hand.R` | `forearm.R` | Right hand |
| 6 | `weapon_grip` | `hand.R` | Weapon attachment point |

**Bone Hierarchy:**
```
Armature
├── upper_arm.L
│   └── forearm.L
│       └── hand.L
├── upper_arm.R
│   └── forearm.R
│       └── hand.R
│           └── weapon_grip
└── fps_viewmodel_arms (MeshInstance3D)
```

**Animations:**

| Animation | Duration | Description |
|-----------|----------|-------------|
| `idle_unarmed` | 1 frame | Default idle pose for first-person arms |

**Mesh:**
- Name: `Cylinder.002`
- Vertices: 896
- Indices: 1320

---

### `assets/characters/player/worldmodel/taco_truck_cook_world.tscn`
Third-person character model imported from Blender (`taco_truck_cook_world.glb`). Features:
- **AnimationTree** with state machine:
  - States: `Start` → `Idle` ↔ `Hold`
  - Transitions with 0.15s crossfade
  - Advance mode set to script-controlled (advance_mode = 0)
- **BoneAttachment3D** on `hand.R` bone (for attaching held objects)
- Textures: Apron, Black, Boot, Glove, Hair, Skin materials

#### Worldmodel glTF Reference (`taco_truck_cook_world.gltf`)

| Property | Value |
|----------|-------|
| Generator | Khronos glTF Blender I/O v4.5.49 |
| glTF Version | 2.0 |
| Binary Data | `taco_truck_cook_world_data.bin` |

**Skeleton Bone List (10 bones):**

| Index | Bone Name | Parent | Description |
|-------|-----------|--------|-------------|
| 0 | `hips` | (root) | Root/pelvis bone |
| 1 | `spine` | `hips` | Torso/spine |
| 2 | `head` | `spine` | Head bone |
| 3 | `leg.R` | `hips` | Right upper leg |
| 4 | `ankle.R` | `leg.R` | Right ankle |
| 5 | `foot.R` | `ankle.R` | Right foot |
| 6 | `leg.L` | `hips` | Left upper leg |
| 7 | `ankle.L` | `leg.L` | Left ankle |
| 8 | `foot.L` | `ankle.L` | Left foot |
| 9 | `neutral_bone` | (root) | Utility bone for neutral pose |

**Bone Hierarchy:**
```
TacoTruckCook_Rig
├── hips
│   ├── spine
│   │   └── head
│   ├── leg.R
│   │   └── ankle.R
│   │       └── foot.R
│   └── leg.L
│       └── ankle.L
│           └── foot.L
├── neutral_bone
├── TacoTruckCook_Body (MeshInstance3D)
└── TacoTruckCook_Head (MeshInstance3D)
```

**Reference Nodes (for Blender setup):**
- `REF_Front` — Front reference plane position
- `REF_Profile` — Side/profile reference plane position  
- `REF_Back` — Back reference plane position

**Animations:**

| Animation | Duration | Description |
|-----------|----------|-------------|
| `Idle` | 1 frame | Default standing pose |
| `Hold` | 1 frame | Pose for holding objects |

**Meshes:**

| Mesh Name | Description | Materials |
|-----------|-------------|-----------|
| `Cylinder` (TacoTruckCook_Body) | Character body | MAT_Black, MAT_Boot, MAT_Glove, MAT_Apron |
| `Cylinder.001` (TacoTruckCook_Head) | Character head | MAT_Skin, MAT_Hair |

**Materials:**

| Material | Metallic | Roughness | Texture File |
|----------|----------|-----------|--------------|
| `MAT_Black` | 0 | 0.85 | `taco_truck_cook_world_img0.png` |
| `MAT_Boot` | 0 | 0.85 | `taco_truck_cook_world_img1.png` |
| `MAT_Glove` | 0 | 0.85 | `taco_truck_cook_world_img2.png` |
| `MAT_Apron` | 0 | 0.85 | `taco_truck_cook_world_img3.png` |
| `MAT_Skin` | 0 | 0.85 | `taco_truck_cook_world_img4.png` |
| `MAT_Hair` | 0 | 0.85 | `taco_truck_cook_world_img5.png` |

---

## Scripts

### Script Catalog

**`res://scripts/gameplay/interactable.gd`** (class_name `Interactable`)
- **Role**: Component that standardizes interaction prompts and signaling.
- **Behavior**:
  - Defines `InteractionType` enum: USE, PICKUP, EXAMINE, CLOSE, OPEN
  - Exports: `enabled` (bool), `prompt_override` (string), `interaction_type` (enum)
  - Signal: `interacted(user: Node)` — emitted when `interact(user)` is called
  - Methods: `get_prompt_text()` returns localized action text, `get_hud_text(key_hint)` formats UI prompt
- **Signal Usage (Important)**:
  - `interacted(user)` is **always emitted** when Player presses E on this object
  - Player **does not wait for or depend on** this signal for pickup
  - Pickup is decided solely by: `interaction_type == PICKUP` and `request_hold()` succeeding
  - The signal is intended for:
    - Item-local logic (sounds, animations, particle effects)
    - UI feedback and notifications
    - Puzzle hooks and scene triggers
    - Custom item-specific behaviors
- **Dependencies**: None; consumed by player raycast logic and scene-specific handlers via signal connections.

**`res://scripts/gameplay/holdable.gd`** (class_name `Holdable`)
- **Role**: Component that controls whether an item can be held and manages hold/release behavior.
- **Behavior**:
  - Exports: `is_holdable` (bool), `is_held` (runtime state), `hold_offset` (Vector3), `hold_rotation_degrees` (Vector3)
  - Exports: `freeze_while_held` (bool), `disable_collisions_while_held` (bool)
  - Signals: `held(user)`, `released(user)`
  - Methods:
    - `can_hold() -> bool` — returns true if holdable and not currently held
    - `on_held(user)` — freezes physics, disables collisions (if configured), emits signal
    - `on_released(user)` — restores physics/collisions, emits signal
    - `get_body() -> RigidBody3D` — returns parent RigidBody3D
- **Dependencies**: Must be child of a `RigidBody3D`; consumed by `player.gd` via `request_hold()`.

**`res://scripts/gameplay/fireable.gd`** (class_name `Fireable`)
- **Role**: Component that controls whether a held item can be fired (used/activated).
- **Behavior**:
  - Exports: `is_fireable` (bool), `is_fired` (runtime state), `fire_duration` (float), `cooldown` (float)
  - Signals: `fired(user)`, `fire_complete`
  - Methods:
    - `can_fire() -> bool` — checks fireable flag, fired state, and cooldown timer
    - `fire(user) -> bool` — attempts to fire, emits `fired(user)`, schedules `fire_complete` after duration
  - Timing: if `fire_duration > 0`, uses timer before emitting `fire_complete`; cooldown prevents rapid refiring
- **Firing Gate (Critical)**:
  - Player calls `fire(user)` **directly** on Left Click
  - Player **does not** call `can_fire()` separately
  - `fire(user)` is the **single authoritative gate** that must internally validate:
    - `is_fireable` flag
    - cooldown timers
    - firing state
  - If `fire(user)` returns `true`, Player will **not** attempt fallback melee
  - If `fire(user)` returns `false`, Player falls back to melee raycast
- **Dependencies**: Optional component on `RigidBody3D` items; consumed by `player.gd` via `_try_fire_or_melee()`.

**`res://scripts/gameplay/target.gd`** (class_name `TargetDummy`)
- **Role**: Simple destructible dummy for testing melee/damage systems.
- **Behavior**:
  - Exports: `max_hits` (int, default 10)
  - Method: `apply_damage(amount: int)` — increments hit counter, calls `queue_free()` when max reached
- **Dependencies**: None; instanced by `scenes/gameplay/target.tscn`.

**`res://scripts/gameplay/interactables/button.gd`**
- **Role**: Minimal demo handler for the interaction system.
- **Behavior**: Connected to sibling `Interactable.interacted` signal; logs user name to console on activation.
- **Dependencies**: Requires sibling `Interactable` node; used in `scenes/gameplay/interactables/button.tscn`.

**`res://scripts/player/player.gd`**
- **Role**: Full FPS character controller with component-based interaction and holding systems.
- **Behavior**:
  - **Movement**: Walk/sprint with configurable speeds and acceleration; jump with gravity; CharacterBody3D capsule collider
  - **Look/Input**: Mouse-look with sensitivity and pitch clamp; Esc toggles mouse capture
  - **Interaction System**:
    - Raycasts `interact_range` meters (default 3m) to find `Interactable` components
    - Updates `InteractPrompt` label with `Interactable.get_hud_text()`
    - On E key: calls `Interactable.interact(self)`, then checks if `interaction_type == PICKUP` to call `request_hold()`
    - Helper: `_find_interactable(hit)` recursively searches node tree for Interactable component
  - **Component-Based Holding System**:
    - Caches: `_held_holdable`, `_held_fireable`, `_held_original_gravity_scale`
    - `request_hold(body: RigidBody3D) -> bool` — validates Holdable component via `can_hold()`, stabilizes velocity, calls `Holdable.on_held(self)`
    - Lerps held item to `HoldPoint`, applies `Holdable.hold_offset` and `hold_rotation_degrees` on snap
    - `_release_held_item_to(parent, world_xform)` — calls `Holdable.on_released(self)`, restores gravity scale
    - `_validate_held_item()` — cleans up all cached refs if item destroyed externally
  - **Drop/Throw**:
    - Q key: `_drop_item()` releases via Holdable component, applies light forward velocity and reduced gravity
    - Right click: `_throw_item()` releases via Holdable component, applies throw velocity with upward bias
  - **Fire System**:
    - Left click: `_try_fire_or_melee()` — prefers `Fireable.fire(self)` if component present and enabled, else falls back to melee raycast
    - Melee: raycasts 2m, calls `apply_damage(1)` on hit if method exists
  - **Animation**: Drives worldmodel `AnimationTree` (Idle/Hold states); debug overrides with H/J keys
  - **Viewmodel**: Maintains dual-camera setup; creates `BoneAttachment3D` for `weapon_grip` bone on FPS arms skeleton
  - **Hand Visibility Override**: Disables depth test on worldmodel materials when holding (prevents hand occlusion)
- **Exports** (organized by category):
  - Movement: walk_speed, sprint_speed, ground_accel, air_accel, jump_velocity
  - Viewmodel: force_hand_visible_when_holding, viewmodel_skeleton_path, right_hand_socket_path
  - Look: mouse_sensitivity, max_pitch_degrees
  - Interaction: interact_range, hold_lerp_speed, hold_snap_distance
  - Drop: drop_forward_velocity, drop_up_velocity, drop_gravity_scale
  - Throw: throw_speed, throw_up_bias
  - Animation: anim_tree_path, debug_anim
- **Dependencies**:
  - Expects `Interactable` components on interactive objects (finds via `_find_interactable()`)
  - Expects `Holdable` component on pickupable items (required for `request_hold()` to succeed)
  - Optional `Fireable` component on held items (checked in `_try_fire_or_melee()`)
  - Expects AnimationTree at `anim_tree_path` with Idle/Hold states
  - Expects viewmodel skeleton at `viewmodel_skeleton_path` with `weapon_grip` bone

---

## Rendering Architecture

The project uses a **dual-camera viewmodel system** to prevent weapon/arm clipping:

| Layer | Cull Mask | Purpose |
|-------|-----------|---------|
| 1     | World     | Environment, world models, other players |
| 2     | Viewmodel | First-person arms only |

- **WorldCamera** (layer 1) renders the main game world
- **ViewModelCamera_VM** (layer 2) renders arms in a separate SubViewport
- SubViewport is overlaid via SubViewportContainer with `transparent_bg = true`
- Viewmodel uses narrower FOV (30°) to reduce distortion on arms

---

## Component System Contract

This section documents the **authoritative design contract** for the component-based interaction system.

---

### ❌ Deprecated / Legacy Hooks (DO NOT USE)

The following methods are **no longer part of the official contract**:
- `finalize_hold()`
- `on_picked_up()`
- `on_dropped(parent, transform)`

These may exist on older items for backwards compatibility only. **New items must not implement or rely on these methods.**

```gdscript
# ❌ DEPRECATED - DO NOT USE
func on_picked_up(player): pass
func on_dropped(parent, transform): pass
```

---

### ✅ Player Authority Rules

`player.gd` is the **sole authority** for:
- Setting and clearing `held_item`
- Reparenting held items
- Applying drop/throw velocities
- Routing input to components

**Items and components must not directly mutate `player.held_item`.**

---

### Scene Structure Requirements

**Required structure for interactive items:**

```
ItemRoot (RigidBody3D)
├─ MeshInstance3D
├─ CollisionShape3D
├─ Interactable   (Node, script=interactable.gd)
├─ Holdable       (Node, script=holdable.gd)
└─ Fireable       (Node, script=fireable.gd)   # optional
```

**Critical: Node Naming Convention**
- Player locates components by **exact node name**, not by type
- Required names (case-sensitive):
  - `Interactable`
  - `Holdable`
  - `Fireable`
- Renaming (e.g., "HoldableComponent") will **break discovery**
- Future versions may support type-based lookup

**Component Parenting:**
- All components must be **direct children** of the root RigidBody3D
- Components control behavior, not state
- Use component signals (`held`, `released`, `fired`, `fire_complete`) for custom logic

---

### Item Authoring Checklist

Use these checklists when creating new interactive items.

#### Pickup-Capable Item

```
✓ Root node is RigidBody3D
✓ Child node named "Interactable" exists
✓ Interactable.interaction_type == PICKUP
✓ Child node named "Holdable" exists
✓ Holdable.is_holdable == true
✓ Item collision_layer matches InteractRay collision_mask (layer bit 4)
```

#### Fire-Capable Item

```
✓ Meets all pickup requirements above
✓ Child node named "Fireable" exists
✓ Fireable.is_fireable == true
✓ Fireable.fire(user) handles all internal validation
```

#### Common Failure Cases

**Item won't pick up:**
- Interactable.interaction_type not set to PICKUP
- Component node renamed or nested incorrectly
- Item collision layer mismatch with InteractRay

**Item won't fire:**
- `is_fireable == false`
- `fire(user)` returns false (check cooldowns/state)
- Fireable not named exactly "Fireable"

**Legacy warning:** Items implementing `on_picked_up()` or `on_dropped()` will not work. Use `Holdable.on_held()` and `Holdable.on_released()` instead.

---

## Notes

- Character model is "Taco Truck Cook" — a stylized humanoid rig from Blender
- The AnimationTree on the worldmodel supports idle/hold states for item holding animations
- The interaction system is fully component-based: add an `Interactable` node to any object and connect to its `interacted` signal
- The holding system uses `Holdable`, `Fireable`, and `Interactable` components for all item behavior
- Project is designed as a reusable drop-in player scene for other Godot projects
