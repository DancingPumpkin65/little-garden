# A little garden

A standalone Godot 4.7.2 playable scene, separate from Bewerbung. Original low-poly 3D characters and a white-to-colour garden, inspired by the broad visual approach of Bryson McBee’s birthday game. No assets from his game are used.

Double-click **Play.cmd** to play. **Open editor.cmd** opens the project for editing. These launchers use the portable Godot runtime installed at `C:/Users/ouass/.local/share/godot-4.7.2`.

Move with WASD or arrows, run with Shift, jump with Space. Approach the golden seed and press E. Hold left mouse to see the trajectory and increase throw strength; release to throw. Hold right mouse and drag to turn the camera. Stand a few steps from the bowl to make a gentle throw. Press R to return the seed to its starting position. Escape opens pause, mute and restart. Falls and lost throws recover automatically.

Plant the seed in the stone bowl to restore the garden, then explore or press E near Ari to talk. This is a short complete scene, not a full game.

## Structure

- `scripts/game.gd`: scene progression, input, camera, seed physics and aiming.
- `scripts/character.gd`: imported Blender model and bone mapping.
- `scripts/legacy/procedural_character.gd`: shared controller/pose logic and complete procedural fallback.
- `art/character/`: editable Blender source, deterministic build script and modeling workflow.
- `assets/characters/reference_character.glb`: runtime player mesh and 15-bone armature.
- `scripts/garden.gd`: island, vegetation and reveal.
- `scripts/interface.gd`: title, dialogue, controls and pause menu.
- `scripts/sound.gd`: original synthesized ambience and chimes.
- `scripts/shapes.gd`: shared mesh construction helpers.

## Verification

Run Godot with `--headless --fixed-fps 60 --path . --quit-after 500 -- --self-test`. The test uses real CharacterBody3D movement and RigidBody3D simulation to verify pickup, throwing into the bowl, the garden reveal and fall recovery. An assertion or missing SELF_TEST_PASS means failure. Rendering checks use `-- --capture=garden` or `-- --capture=seed`; the captured frame is saved to `artifacts/garden.png` or `artifacts/seed.png`.

The player is modeled in Blender and imported as GLB. The companion and environment remain procedural. Launch Godot with `-- --procedural-character` to use the previous player model; gameplay and animation states share the same controller. The editable `.blend` source stays outside Godot import/export through `art/.gdignore`. Desktop keyboard/mouse is supported; mobile and controller input are not implemented. No network, accounts, telemetry or backend.

Character QA follows `references/README.md`, using screenshots of the original game and equal-height front/rear/bent-pose comparisons.

Imported-model checks: run `--headless --path . --quit-after 60 --script tests/imported_character.gd`. The fallback geometry check is `tests/character_shape.gd`. `tests/imported_character_render.gd` measures 240 uncapped rendered frames after warmup in the garden scene; one local AMD Radeon compatibility-renderer run averaged 2.85 ms per frame. This is a small local benchmark, not a frame-rate guarantee on other machines.
