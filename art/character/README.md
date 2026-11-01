# Blender character workflow

The editable player is `reference_character.blend`. The runtime model is `../../assets/characters/reference_character.glb`. Blender 4.5.9 LTS generated the source with `bpy`; Godot 4.7.2 imports the GLB directly. Neither Blender nor its Python runtime is needed to play.

Build static geometry first:

```
blender --background --factory-startup --python art/character/build_character.py
```

Inspect `artifacts/blender-character/front.png`, `side.png` and `back.png`. `compare_views.py` takes `--front`, `--side`, `--back` reference paths, `--renders` and `--output` to compose equal-height comparisons. The supplied references are screenshots with perspective, so silhouette comparisons are visual estimates. Keep reference images local and outside game exports. Record the review in `STATIC_REVIEW.md` before rigging.

After static review:

```
blender --background --factory-startup --python art/character/build_character.py -- --rig --skip-render
```

This saves the editable meshes, weights and armature to the `.blend`, then joins export copies into one mesh with two material surfaces. The GLB contains 3,658 triangles, 15 bones, two matte materials and no image textures. Coordinate conversion maps Blender Z-up/-Y-forward to Godot Y-up/+Z-forward.

The active `GardenCharacter` inherits the existing controller and pose equations from `scripts/legacy/procedural_character.gd`. It maps the head, upper arms, forearms, thighs and calves to the imported armature. Rest rotations must be preserved: Godot imported bone pose rotations include their rest orientation. Replacing them with identity folds downward-pointing limbs upward. Tests cover that failure through hand movement and return-to-idle checks.

Existing procedural animation already supplies idle, walk, sprint, airborne and carrying states, so AnimationPlayer/AnimationTree and baked Blender actions are unnecessary here. The companion retains its procedural identity. The previous player is available with `-- --procedural-character`.

Run `tests/imported_character.gd` in headless Godot for bone presence, normalized skinning, triangle/material budget and pose transitions; run the gameplay `--self-test` with both visual modes. Inspect Godot captures `characters`, `characters-side`, `characters-back`, `characters-motion`, `characters-jump` and `characters-carry` after any geometry or bind-pose change. `tests/imported_character_render.gd` performs a short native rendered benchmark in the full garden scene.
