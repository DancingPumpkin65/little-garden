# A little garden

A standalone Godot 4.7.2 scene, separate from Bewerbung. Original low-poly characters inspired by the broad visual approach of Bryson McBee's birthday game. No assets from his game are used.

Double-click **Play.cmd** to play. **Open editor.cmd** opens the project. Both use the portable runtime at `C:/Users/ouass/.local/share/godot-4.7.2`.

## Current playable sequence

The maps and door use a black-and-white theme: white ground, a black background and a gray/white doorway. The girl keeps her hijab, glasses and flower. Her companion starts without his head, right arm or left leg, and hops ahead and to her side. Small gray dust puffs appear at moving feet.

The first map contains only the target and door. The supplied Latin-letter Darija dialogue plays as queued speech bubbles, with typing and murmurs. Misses use the five supplied responses in order; later misses keep the final response. The success line depends on whether the fruit lands in one/two attempts or takes more tries. A successful throw reveals the whole right arm. It can be picked up, thrown again with the supplied reaction, or returned. He waits in place from pickup until the arm is restored. His restored right arm joins the one-leg hop. Returning it plays his arm celebration and the two supplied lines. The unlocked door sits at the first map boundary. It opens onto a 80-unit narrow passage fading into darkness ahead. A second door appears near the far end and opens on approach. Both characters walk into the quest without a fade, teleport, or input lock. After both pass the second door, it closes and the old map and passage are hidden and lose their collisions.

The passage leads to two 70-unit-wide white rectangular platforms separated by an unreachable 20-unit gap. The near platform is 48 units deep and the far platform is 40 units deep. The floor shades to gray with distance, matching the supplied reference views. The gap dialogue starts near the edge, after the player crosses the large empty approach. The loose left leg hops on the far side. After the supplied two lines, the companion runs, jumps and falls without respawning. The far platform and leg fade smoothly to black over 1.4 seconds. Falling from the player's platform is the unannounced exit, followed by a full black transition.

The girl then drops onto a vast white floor that fades to darkness before any edge can be seen. The companion and left leg are ahead of her. Work stops at this arrival; there is no further leg interaction or quest yet. The supplied wording is preserved, including "yedi" while looking at the leg.

## Controls

WASD/arrows move, Shift runs, Space jumps. E picks up the fruit or arm, returns the arm near the companion, or talks. Hold left mouse to aim and charge the fruit or carried arm, then release to throw. Mouse movement orbits and tilts the camera. R recovers the fruit; Escape pauses and frees the cursor. Start again clears the paused tree before reloading to the title. Falls recover in the first map. In the gap chapter, falling intentionally progresses the story.

## Structure

- `scripts/game.gd`: progression, input, dialogue beats, throw outcomes and camera.
- `scripts/character.gd`: imported rig, action poses, one-leg companion hop and head flower.
- `scripts/companion_parts.gd`: missing body sections and the exact recoverable arm mesh.
- `scripts/recovery_part.gd`: emergence, pickup, carrying and animated restoration.
- `scripts/garden.gd`: white first map, target, closing door and continuous passage.
- `scripts/journey.gd`: connected quest platforms, scripted failed jump and dark arrival.
- `scripts/foot_dust.gd`: pooled gray foot puffs.
- `scripts/interface.gd`: speech bubbles, typewriter, title and pause menu.
- `scripts/sound.gd`: generated murmurs, jump sound, ambience and chimes.
- `art/character/`: editable Blender sources and deterministic modeling scripts.
- `scripts/legacy/procedural_character.gd`: shared controller and procedural fallback.

Blender produces the body GLBs; Godot keeps the controller and animation logic. `-- --procedural-character` selects the legacy visual fallback. Source art stays outside Godot import/export through `.gdignore`. Desktop keyboard/mouse only. No network, accounts or backend.

## Verification

Run these with Godot's `--headless --fixed-fps 60 --path .` flags:

- `--quit-after 11000 --script tests/journey_flow.gd`: complete connected sequence, exact dialogue, hand throw, dust, formation, seamless passage traversal, door closure, the fall fade, non-respawning companion and final arrival. Append `-- --procedural-character` for the legacy visuals.
- `--quit-after 7500 --script tests/doorway_flow.gd`: boundary door, continuous dark passage, second door, arrival closure, hidden old world and disabled old collisions. Append `-- --capture-doorway` with the native renderer for reference-view captures.
- `--quit-after 1000 --script tests/handoff_restart.gd`: stationary handoff, restored arm in the hop, and movement after restarting from pause.
- `--quit-after 1100 --script tests/scenario_one.gd`: real throw, whole-arm reward, pickup, pause/fall recovery, restoration and door completion. Append `-- --procedural-character` for the fallback.
- `--quit-after 1100 --script tests/hop_and_misses.gd`: hop phases, larger empty map, full-arm geometry and one rotating joke per missed physics throw.
- `--quit-after 500 -- --self-test`: controller, timed throw, target trigger, reveal and fall recovery.
- `--quit-after 180 --script tests/fruit_attachment.gd`: hand attachment, camera orbit and throw timing.
- `--quit-after 550 --script tests/dialogue_movement.gd`: typing, murmurs, pause, grounding, carrying control and player jump.
- `--quit-after 60 --script tests/imported_character.gd`: both GLBs, normalized weights, rig and pose transitions.

An assertion/error or missing PASS marker means failure. Run the journey test with the native renderer and `-- --capture-journey` to save screenshots of the story beats in `artifacts/`. Character QA follows `references/README.md`; model source editing follows `art/character/README.md`.
