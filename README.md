# A little garden

A standalone Godot 4.7.2 playable scene, separate from Bewerbung. Original low-poly 3D characters and a white-to-colour garden, inspired by the broad visual approach of Bryson McBeeÃ¢â‚¬â„¢s birthday game. No assets from his game are used.

Double-click **Play.cmd** to play. **Open editor.cmd** opens the project for editing. These launchers use the portable Godot runtime installed at `C:/Users/ouass/.local/share/godot-4.7.2`.

Move with WASD or arrows, run with Shift, jump with Space. Approach the golden seed and press E. Hold left mouse to see the trajectory and increase throw strength; release to throw. Move the mouse to orbit and tilt the camera. Escape frees the cursor for the menu. Stand a few steps from the bowl to make a gentle throw. Press R to return the seed to its starting position. Escape opens pause, mute and restart. Falls and lost throws recover automatically.

The companion starts without his head, right hand and left leg, and follows the girl in short hops. Throw the fruit into the circle to grow the garden and reveal his head and hand. Press E near a part to pick it up, then E near him to return it. Restore both parts to light the path to the door. Press E by the door to open it, then walk through to finish this first scenario. His left leg remains missing for a later scene. Dialogue is Moroccan Darija in Arabic script, with typing and murmurs. The girl wears a small flower above her hijab. No second scenario is implemented yet.

## Structure

- `scripts/game.gd`: scene progression, input, camera, seed physics and aiming.
- `scripts/character.gd`: imported Blender model and bone mapping.
- `scripts/legacy/procedural_character.gd`: shared controller/pose logic and complete procedural fallback.
- `art/character/`: editable Blender source, deterministic build script and modeling workflow.
- `assets/characters/reference_character.glb`: runtime player mesh and 15-bone armature.
- `scripts/companion_parts.gd`: missing body sections and exact recoverable meshes from the imported character.
- `scripts/recovery_part.gd`: emerging, pickup, carry and return states.
- `scripts/garden.gd`: island, vegetation, lit route and hinged door.
- `scripts/interface.gd`: title, character speech bubbles and pause menu.
- `scripts/sound.gd`: original synthesized ambience and chimes.
- `scripts/shapes.gd`: shared mesh construction helpers.

## Verification

Run Godot with `--headless --fixed-fps 60 --path . --quit-after 500 -- --self-test`. The test uses real CharacterBody3D movement and RigidBody3D simulation to verify pickup, throwing into the bowl, the garden reveal and fall recovery. An assertion or missing SELF_TEST_PASS means failure. Rendering checks use `-- --capture=garden` or `-- --capture=seed`; the captured frame is saved to `artifacts/garden.png` or `artifacts/seed.png`.

The player is modeled in Blender and imported as GLB. The companion also uses a Blender face/body variant; the environment remains procedural. Launch Godot with `-- --procedural-character` to use the previous player model; gameplay and animation states share the same controller. The editable `.blend` source stays outside Godot import/export through `art/.gdignore`. Desktop keyboard/mouse is supported; mobile and controller input are not implemented. No network, accounts, telemetry or backend.

Character QA follows `references/README.md`, using screenshots of the original game and equal-height front/rear/bent-pose comparisons.

Imported-model checks: run `--headless --path . --quit-after 60 --script tests/imported_character.gd`. The fallback geometry check is `tests/character_shape.gd`. `tests/imported_character_render.gd` measures 240 uncapped rendered frames after warmup in the garden scene; a local AMD Radeon compatibility-renderer run with both refined models averaged 2.45 ms per frame. This is a small local benchmark, not a frame-rate guarantee on other machines.

Interaction regression: run `--headless --fixed-fps 60 --path . --quit-after 180 --script tests/fruit_attachment.gd`. This checks the reach, two-handed grip, camera yaw/pitch, retained fruit during windup, release keyframe and follow-through. `tests/capture_interactions.gd` captures those poses and the speech bubble in the native renderer. Dialogue follows Ari in a white bubble with a black shadow; bottom control hints are removed. The fruit follows the imported wrist bones and releases 0.4 seconds into the 0.7-second throw. The trajectory preview uses that release pose.

Dialogue types at about 29 letters per second with punctuation pauses and quiet generated murmurs. Jumping raises the arms, splits the legs and plays a short generated takeoff sound. Carrying follows movement; holding the aim button turns toward the camera direction. Visible mesh soles align with the collision floor. `tests/dialogue_movement.gd` checks typing/replacement/pause, murmur events and PCM output, floor contact, carrying direction, jump pose and landing. Run it headlessly with `--fixed-fps 60 --quit-after 350`. `tests/capture_jump_dialogue.gd` captures the real jump and partial dialogue with the native renderer.

Scenario verification: `--headless --fixed-fps 60 --path . --quit-after 1000 --script tests/scenario_one.gd` runs the complete first scenario through the actual physics and interactions, including hopping, pause/fall recovery, both restorations and the door. Append `-- --procedural-character` to check the legacy fallback. Use the native renderer with `-- --capture-scenario` for screenshots of the initial companion, rewards, carried parts and unlocked route. The removed objective/completion headings stay empty and hidden.
