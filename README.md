# A little garden

A standalone Godot 4.7.2 scene, separate from Bewerbung. Original low-poly characters inspired by the broad visual approach of Bryson McBee's birthday game. No assets from his game are used.

Double-click **Play.cmd** to play. **Open editor.cmd** opens the project. Both use the portable runtime at `C:/Users/ouass/.local/share/godot-4.7.2`.

## First scenario

The companion has lost his head, whole right arm and left leg. He follows the girl with a dedicated one-leg hop: crouch, push-off, tucked flight and landing. The girl keeps her hijab, glasses and head flower.

The larger clearing contains only the ground, a target circle and a closed door at the far front. Throwing the fruit into the circle reveals only his right arm. Carry it back to him to restore it and open the door. Walking through finishes this scene. His head and left leg remain missing for later stages, which are not implemented yet.

Dialogue uses Latin-letter Moroccan Darija with typing and soft murmurs. The opening sets up the missing parts and mysterious door. Missed throws get rotating, supportive jokes, once per attempt. The map has no trees, flowers, bench, decorative stones or path markers. There are no objective/completion headings.

## Controls

WASD/arrows move, Shift runs, Space jumps. E picks up the fruit or arm, returns the arm near the companion, or talks. Hold left mouse to aim and charge the fruit, then release to throw. Mouse movement orbits and tilts the camera. R recovers the fruit; Escape pauses and frees the cursor. Falls and lost throws recover automatically.

## Structure

- `scripts/game.gd`: progression, input, dialogue beats, throw outcomes and camera.
- `scripts/character.gd`: imported rig, action poses, one-leg companion hop and head flower.
- `scripts/companion_parts.gd`: missing body sections and the exact recoverable arm mesh.
- `scripts/recovery_part.gd`: emergence, pickup, carrying and animated restoration.
- `scripts/garden.gd`: larger empty floor, target and hinged door.
- `scripts/interface.gd`: speech bubbles, typewriter, title and pause menu.
- `scripts/sound.gd`: generated murmurs, jump sound, ambience and chimes.
- `art/character/`: editable Blender sources and deterministic modeling scripts.
- `scripts/legacy/procedural_character.gd`: shared controller and procedural fallback.

Blender produces the body GLBs; Godot keeps the controller and animation logic. `-- --procedural-character` selects the legacy visual fallback. Source art stays outside Godot import/export through `.gdignore`. Desktop keyboard/mouse only. No network, accounts or backend.

## Verification

Run these with Godot's `--headless --fixed-fps 60 --path .` flags:

- `--quit-after 1000 --script tests/scenario_one.gd`: real throw, whole-arm reward, pickup, pause/fall recovery, restoration and door completion. Append `-- --procedural-character` for the fallback.
- `--quit-after 1100 --script tests/hop_and_misses.gd`: hop phases, larger empty map, full-arm geometry and one rotating joke per missed physics throw.
- `--quit-after 500 -- --self-test`: controller, timed throw, target trigger, reveal and fall recovery.
- `--quit-after 180 --script tests/fruit_attachment.gd`: hand attachment, camera orbit and throw timing.
- `--quit-after 350 --script tests/dialogue_movement.gd`: typing, murmurs, pause, grounding, carrying control and player jump.
- `--quit-after 60 --script tests/imported_character.gd`: both GLBs, normalized weights, rig and pose transitions.

An assertion/error or missing PASS marker means failure. Run the scenario test with the native renderer and `-- --capture-scenario` to save screenshots in `artifacts/`. Character QA follows `references/README.md`; model source editing follows `art/character/README.md`.
