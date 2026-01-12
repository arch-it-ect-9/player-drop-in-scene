# Player Drop-In Scene — Workspace Summary

**Date:** January 12, 2026  
**Engine:** Godot 4.5.1 (Forward Plus renderer)  
**Modeler/Asset Tool:** Blender 4.5  
**Project Name:** `Player_DropInScene`

---

## Project Overview

This is a first-person player controller template/drop-in scene for Godot 4.5. The project demonstrates a complete FPS character setup with separate viewmodel and worldmodel rendering, object pickup mechanics, and basic interaction systems.

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
│   └── props/
│       └── pickup_cube/
│           ├── pickup_cube.gd                # PickupCube class
│           └── pickup_cube.tscn              # uid://c2pp4d1yn3yo0
│               └── PickupCube (RigidBody3D, collision_layer=4, script=pickup_cube.gd)
│                   ├── CollisionShape3D (BoxShape3D 0.25³, y=0.225)
│                   └── MeshInstance3D (BoxMesh 0.25³, y=0.225)
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
│   │   └── target.tscn                       # uid://d1cw1gxmumlhg
│   │       └── Target (StaticBody3D, script=target.gd)
│   │           ├── CollisionShape3D (BoxShape3D)
│   │           └── MeshInstance3D (BoxMesh)
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
│               ├── PickupCube (instance of pickup_cube.tscn)
│               └── Target (instance of target.tscn, z=-10.825)
│
└── scripts/
    ├── gameplay/
    │   └── target.gd                         # class_name TargetDummy
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
| Crosshair | `$HUD/Crosshair` |
| ViewModelViewport | `$HUD/ViewModelViewportContainer/ViewModelViewport` |
| ViewModelCamera_VM | `$HUD/ViewModelViewportContainer/ViewModelViewport/ViewModelWorld/ViewModelCamera_VM` |
| ViewModelRoot_VM | `$HUD/ViewModelViewportContainer/ViewModelViewport/ViewModelWorld/ViewModelRoot_VM` |
| fps_viewmodel_arms | `$HUD/ViewModelViewportContainer/ViewModelViewport/ViewModelWorld/ViewModelRoot_VM/fps_viewmodel_arms` |
| TacoTruckCookVisual | `$Visuals/TacoTruckCookVisual` |
| AnimationTree (worldmodel) | `$Visuals/TacoTruckCookVisual/AnimationTree` |

From `pickup_cube.gd` (attached to PickupCube node):
| Node | Path from PickupCube |
|------|----------------------|
| CollisionShape3D | `$CollisionShape3D` |
| MeshInstance3D | `$MeshInstance3D` |

---

## Input Map

| Action        | Key/Button         |
|---------------|--------------------|
| `move_forward`| W                  |
| `move_back`   | S                  |
| `move_left`   | A                  |
| `move_right`  | D                  |
| `jump`        | Space              |
| `sprint`      | Shift              |
| `fire`        | Left Mouse Button  |
| `interact`    | E                  |
| `drop_item`   | Q                  |

---

## Scenes

### `scenes/levels/test_level.tscn`
The main scene and entry point. Contains:
- **WorldEnvironment** with procedural sky
- **DirectionalLight3D** for scene lighting
- **Floor** — 50×50 unit StaticBody3D platform
- **Player** — instanced player scene
- **PickupCube** — physics-based interactable cube
- **Target** — target dummy at position (0.06, 0, -10.825)

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
  - **ViewModelViewportContainer** → **ViewModelViewport** (SubViewport)
    - Separate rendering layer for first-person arms
    - **ViewModelCamera_VM** — cull_mask=2, FOV=30°
    - **ViewModelRoot_VM** → **fps_viewmodel_arms** instance
- **Visuals** → **TacoTruckCookVisual** — Third-person world model (for multiplayer/mirrors)

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

### `assets/props/pickup_cube/pickup_cube.tscn`
Physics-based interactable cube (RigidBody3D):
- Size: 0.25×0.25×0.25 units
- Collision layer: 4 (interactables)
- `pickup_cube.gd` script attached

---

## Scripts

### `scripts/gameplay/target.gd`
```gdscript
class_name TargetDummy
extends StaticBody3D
```
Simple destructible target:
- `@export var max_hits := 10` — Hits before destruction
- `apply_damage(amount: int)` — Accumulates hits, calls `queue_free()` when max reached

### `assets/props/pickup_cube/pickup_cube.gd`
```gdscript
class_name PickupCube
extends RigidBody3D
```
Fully-featured pickup object with state management:
- Captures and restores default physics/collision settings
- `on_picked_up(holder: Node3D, snap: bool)`:
  - Freezes physics, zeros velocity
  - Optionally disables collision while held
  - Can snap immediately or allow smooth interpolation
- `on_dropped(drop_parent: Node, drop_transform: Transform3D)`:
  - Reparents to world, restores physics
  - Unfreezes for simulation

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

## Notes

- Character model is "Taco Truck Cook" — a stylized humanoid rig from Blender
- The AnimationTree on the worldmodel suggests support for idle/hold states (likely for item holding animations)
- InteractRay uses collision mask 4, matching the PickupCube's collision layer 4
- Project is set up as a reusable drop-in player scene for other Godot projects
