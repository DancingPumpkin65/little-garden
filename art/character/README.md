# Modular Blender character workflow

The active workflow is `modular_character.py`, followed by `build_wardrobe.py`. The earlier `refine_character.py` and `build_character.py` are historical sources of control cages and identity details. Do not use their fused-body export as the active character workflow.

## Reusable body template

`reference_character.blend` and `companion_character.blend` contain ten independent body meshes under the existing 15-bone armature:

HEAD, TORSO, ARM_LEFT, ARM_RIGHT, HAND_LEFT, HAND_RIGHT, LEG_LEFT, LEG_RIGHT, FOOT_LEFT, FOOT_RIGHT.

Face, hood or hair, glasses and facial accessories remain separate identity meshes bound to the head bone. Each body module has its own mesh datablock and origin. Arms remain continuous across the elbow and legs across the knee; hands and feet stay independent. Small shoulder, wrist, hip and ankle overlaps conceal the joints.

The proportion pass changes control-cage vertices rather than increasing geometry: a larger head relative to the body, a shorter and wider torso, bowed chunky limbs, flattened irregular mittens and forward-projecting shoes. The original identity is scaled as one unit. Rest-bone positions follow these proportion edits so the existing pose controller still bends at the joints. The earlier pre-soft and identity source files preserve the previous editable geometry.

Run Blender in background with `--python art/character/modular_character.py -- --girl` or `--guy`. Inspect front, side and back renders in `artifacts/modular-review/` before adding `--export`. Export preserves separate mesh nodes; it never joins or voxel-unions the body. `modular-report.json` records the independent object and transform checks.

## Independent clothing

`build_wardrobe.py` first verifies all ten body modules. It creates SWEATER_TORSO, SWEATER_SLEEVE_LEFT, SWEATER_SLEEVE_RIGHT, PANTS_LEFT, PANTS_RIGHT, SHOES_LEFT, SHOES_RIGHT and optional collar, waistband and cuffs. Custom profiles and one existing level of silhouette subdivision round their control cages. No cloth simulation, particle fur, body recoloring or body-clothing union is used.

The sweater torso and waistband follow the body bone. Sleeves blend only between their matching upper-arm and forearm bones; trousers blend only between their thigh and calf bones. Shoes follow the foot bones. This prevents nearby hands or thighs from dragging the sweater torso during animation.

Run `build_wardrobe.py -- --girl` or `--guy`, inspect the three views in `artifacts/wardrobe/`, then add `--export`. Editable garment scenes are `girl_wardrobe.blend` and `guy_wardrobe.blend`. GLBs are under `assets/characters/`. Garments and body modules retain independent transforms in Blender and Godot.

## Godot verification

`GardenCharacter` keeps the existing controller and pose equations. Birthday garments bind to its existing Skeleton3D. Covered body modules are hidden while hands, face, identity details and the separate shoes remain visible. `GardenCompanionParts` hides or restores whole modules and builds collectible geometry from those modules. The earlier procedural fallback remains available with `-- --procedural-character`.

Run `tests/imported_character.gd` to check ten body modules, the bone contract, finite vertices and normalized weights. Run `tests/soft_visuals.gd` for garment modules, binding and torso-weight isolation. Native execution captures front, side, back, walk, jump and throw poses in `artifacts/soft-review/`.

Run `tests/journey_flow.gd`, `tests/reunion_cake.gd` and the normal `--self-test` after rig or interaction changes. `tests/reunion_cake.gd -- --capture-reunion` captures the actual native game sequence. The before/after sheets under `artifacts/proportion-review/` use equal displayed character heights and matching camera angles.

Study references are in the adjacent Bewerbung workspace's `game reference` folder. They are not shipping assets. Preserve the girl's hijab, glasses and flower and the guy's short hair, rectangular glasses, mustache and goatee.

## Static shape refinement

`static_shapes.py` edits the existing control-cage vertices for a less regular torso, fuller shoulders, uneven mitten palms, shaped lower legs and shoes with a heel and toe box. Body topology, identity meshes, bone rest transforms and gameplay animation equations remain unchanged in this pass. Garments remain independent; their torso follows the same small silhouette edits.

Before editing, save the baseline body Blender files under `artifacts/final-static/baseline-reference_character.blend` and `baseline-companion_character.blend`. `validate_static_revision.py` compares the revised files against those baselines and checks exact identity and rest-rig equality, unchanged body vertex/face counts and ten independent meshes.

`tests/soft_visuals.gd -- --static-only` captures imported static views without running the walking, jumping or throwing previews. Walking refinement is a separate contribution after static review. Published comparison renders are in `docs/reviews/static-character/`.
