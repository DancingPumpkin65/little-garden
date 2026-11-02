# Blender character workflow

The girl is `reference_character.blend`; the guy is `companion_character.blend`. Both are exported as matching GLBs under `assets/characters/`. Blender is only needed for editing, not playing.

## Edit and review

`refine_character.py` opens the preserved `reference_character_base.blend` and edits its actual mesh vertices. It retains the 15-bone armature. The old disconnected body shells made organic junctions impractical, so only the edited body and skull are retopologized. Body surfaces are voxel-united, physically relaxed, reduced to broad low-poly facets, then assigned barycentrically transferred and normalized weights from the original surfaces. This removes lathe bands and hard shoulder/wrist/hip/ankle joins. The rounded skull uses blended corner normals; body and cloth remain flat shaded. No subdivision or textures are added.

```
blender --background --factory-startup --python art/character/refine_character.py
```

Inspect the front, side and back PNGs for both variants under `artifacts/sculpt-review/`. Check silhouette and accessory clipping before export. The original game screenshots guide body shape; the supplied photos guide only simple identity features. They remain local study references and are not embedded as textures.

After static review:

```
blender --background --factory-startup --python art/character/refine_character.py -- --export --skip-render
```

Editable meshes and armatures are saved before copies are joined for runtime export. Each GLB has one mesh, two matte material surfaces, 15 bones and fewer than 5,000 triangles. Current counts are in `model-report.json`. The baseline makes repeated edits non-cumulative. `build_character.py` is the earlier baseline-construction script, not the active refinement workflow.

## Godot validation

`GardenCharacter` inherits the existing controller and pose equations from `scripts/legacy/procedural_character.gd`. The player loads the hijab variant and the companion loads the guy. Bone rotations are mapped on top of the imported rest orientations. The existing idle, walk, sprint, airborne and carrying states remain procedural; no AnimationTree or baked replacement actions are required. `-- --procedural-character` selects the complete previous implementation.

Run `tests/imported_character.gd` in headless Godot to check both assets, skin weights, triangle/material budgets and pose transitions. Run the gameplay `--self-test` with both visual modes. Inspect Godot captures `characters`, `characters-side`, `characters-back`, `characters-motion`, `characters-jump` and `characters-carry`. `tests/imported_character_render.gd` runs a short native rendered benchmark in the garden scene.

The guy has rounded rectangular frames. A narrow gap beside the ribs and hips prevents the voxel pass from welding wrists to the torso; wrist and elbow bone rests follow the adjusted arm geometry. Check the raised-arm throw pose as well as walking after changes. Pickup and throwing use the existing pose controller with a timed action overlay and a wrist-spacing solve that keeps both mittens around the fruit.

Scenario one partitions the companion runtime mesh by existing skin influences to hide his head, complete right arm and left leg. The first-stage arm collectible comes from those same triangles and materials; the head stays missing. Restoration rebuilds the visible index lists while retaining the imported skin and controller. Blender source remains complete. The small flower is a lightweight head-bone accessory added in Godot, separate from the editable Blender body.
