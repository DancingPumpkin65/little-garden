# A Little Interlude

A standalone Godot 4.7.2 scene, separate from Bewerbung. Original low-poly characters inspired by the broad visual approach of Bryson McBee's birthday game. No assets from his game are used.

Double-click **Play.cmd** to play. **Open editor.cmd** opens the project. Both use the portable runtime at `C:/Users/ouass/.local/share/godot-4.7.2`.

## Current playable sequence

The maps and door use a black-and-white theme: white ground, a black background and a gray/white doorway. The girl keeps her hijab, glasses and flower. Her companion starts without his head, right arm or left leg, and hops ahead and to her side. Small gray dust puffs appear at moving feet.

The first map contains only the target and door. The supplied Latin-letter Darija dialogue plays as queued speech bubbles, with typing and murmurs. Misses use the five supplied responses in order; later misses keep the final response. The success line depends on whether the fruit lands in one/two attempts or takes more tries. A successful throw reveals the whole right arm. It can be picked up, thrown again with the supplied reaction, or returned. He waits in place from pickup until the arm is restored. His restored right arm joins the one-leg hop. Returning it plays his arm celebration and the two supplied lines. The unlocked door sits at the first map boundary. It opens onto an 80-unit-long, 5-unit-wide passage fading into darkness ahead. The companion uses a separate side lane while running through it. Both door openings are 4.5 units wide. A second door appears near the far end and opens on approach. Both characters walk into the quest without a fade, teleport, or input lock. After both pass the second door, it closes and the old map and passage are hidden and lose their collisions.

The passage leads to two 70-unit-wide white rectangular platforms separated by an unreachable 20-unit gap. The near platform is 48 units deep and the far platform is 40 units deep. The floor shades to gray with distance, matching the supplied reference views. The gap dialogue starts near the edge, after the player crosses the large empty approach. The loose left leg hops on the far side. After the supplied two lines, the companion runs, jumps and falls without respawning. The far platform and leg fade smoothly to black over 1.4 seconds. Falling from the player's platform is the unannounced exit, followed by a full black transition.

The girl then drops onto a broad white floor fading into darkness. He greets her with the supplied Darija lines, the leg floats back into place, and he switches to a normal two-leg walk. He leads while waiting if she falls behind. Seven small flowers sprout along the first approach and two more along the next passage. Their stems extend before leaves and petals unfold; flower roots keep a fixed scale. He reaches for the handle, bows slightly and opens the paneled door with "Khalini n7al lik lbab ;)". The same gesture and line now open the first-stage door too.

The next map contains a pink cake under a transparent rounded glass case on a stepped white plinth. His head is beside it. E picks up the head with the reach animation; hold and release left mouse to use the existing overhand throw. The first two head impacts add cracks and shake the glass. The third emits animated shards and a shattering sound, then clears the barrier. Each throw counts once. Missed heads return if they fall outside the map. The first two misses and all three impacts use the supplied Darija reactions. Once the loose head is encountered, speech follows it on the ground, while carried, and during its flight.

The third hit starts the birthday transformation. The cake rises into a large pink blossom tree while the white map becomes a green garden with 18 pastel trees, 96 flowers in mixed beds, a winding stepping-stone path and drifting blossom petals. Flowers grow stems and unfold buds instead of enlarging whole plants. The girl changes into a cyan sweater and cyan pants with soft cuffs; he changes into a blue sweater and black pants. Clothing uses the existing rig weights, preserving hands, faces, glasses and hijab. The five supplied birthday lines play in order, ending with the invitation to explore. Movement stays available during the reveal.

Speech is measured for the full message before typing begins. The panel paints its own black shadow from the same bounds; only the pointer and its small shadow are separate shapes. Long messages expand the panel and short follow-ups shrink it without changing size letter by letter.

All supplied Latin-letter Darija wording is preserved, including "yedi" in the earlier leg dialogue.

## Controls

WASD/arrows move, Shift runs, Space jumps. E picks up the fruit or arm, returns the arm near the companion, or talks. In the cake map, E picks up the head. Hold left mouse to aim and charge the fruit, carried arm, or head, then release to throw. Mouse movement orbits and tilts the camera. R recovers the fruit; Escape pauses and frees the cursor. Start again clears the paused tree before reloading to the title. Falls recover in the first map. In the gap chapter, falling intentionally progresses the story.

## Structure

- `scripts/game.gd`: progression, input, dialogue beats, throw outcomes and camera.
- `scripts/character.gd`: imported rig, action poses, one-leg companion hop and head flower.
- `scripts/companion_parts.gd`: missing body sections and the exact recoverable arm mesh.
- `scripts/recovery_part.gd`: emergence, pickup, carrying and animated restoration.
- `scripts/garden.gd`: white first map, target, closing door and continuous passage.
- `scripts/journey.gd`: connected quest platforms, scripted failed jump and dark arrival.
- `scripts/reunion.gd`: leg reunion, walking leader, flowers, gentleman door and cake map.
- `scripts/story_door.gd`: paneled door mesh, hinge and collision.
- `scripts/glass_case.gd`: swept head impacts, three-hit cracks, glass barrier and animated shards.
- `scripts/birthday_garden.gd`: cake morph, colored ground, flower beds, trees and drifting petals.
- `scripts/growing_flower.gd`: extending stems with hinged leaves and unfolding petals.
- `scripts/growing_tree.gd`: growing branch geometry, crown buds and matching trunk collision.
- `scripts/foot_dust.gd`: pooled gray foot puffs.
- `scripts/interface.gd`: speech bubbles, typewriter, title and pause menu.
- `scripts/sound.gd`: generated murmurs, jump sound, ambience and chimes.
- `art/character/`: editable Blender sources and deterministic modeling scripts.
- `scripts/legacy/procedural_character.gd`: shared controller and procedural fallback.

Blender produces the body GLBs; Godot keeps the controller and animation logic. `-- --procedural-character` selects the legacy visual fallback. Source art stays outside Godot import/export through `.gdignore`. Desktop keyboard/mouse only. No network, accounts or backend.

## Verification

Run these with Godot's `--headless --fixed-fps 60 --path .` flags:

- `--quit-after 18000 --script tests/reunion_cake.gd`: exact reunion dialogue, leg restoration, two-leg leader, sparse flowers, door gesture, head pickup/throws, three real impacts, shatter cleanup, exact hit/miss reactions, head speech anchor, birthday sequence, clothing coverage, stem growth, missed-head recovery and restart. Append `-- --capture-reunion` with the native renderer to capture the sequence.
- `--quit-after 11000 --script tests/journey_flow.gd`: complete connected sequence, exact dialogue, hand throw, dust, formation, seamless passage traversal, door closure, the fall fade, non-respawning companion and final arrival. Append `-- --procedural-character` for the legacy visuals.
- `--quit-after 7500 --script tests/doorway_flow.gd`: boundary door, continuous dark passage, second door, arrival closure, hidden old world and disabled old collisions. Append `-- --capture-doorway` with the native renderer for reference-view captures.
- `--quit-after 30 --script tests/bubble_layout.gd`: full-message sizing, stable typing bounds and matching shadow layout.
- `--quit-after 1000 --script tests/handoff_restart.gd`: stationary handoff, restored arm in the hop, and movement after restarting from pause.
- `--quit-after 1500 --script tests/scenario_one.gd`: real throw, whole-arm reward, pickup, pause/fall recovery, restoration and door completion. Append `-- --procedural-character` for the fallback.
- `--quit-after 1100 --script tests/hop_and_misses.gd`: hop phases, larger empty map, full-arm geometry and one rotating joke per missed physics throw.
- `--quit-after 750 -- --self-test`: entrance, controller, timed throw, target trigger, reveal and fall recovery.
- `--quit-after 180 --script tests/fruit_attachment.gd`: hand attachment, camera orbit and throw timing.
- `--quit-after 550 --script tests/dialogue_movement.gd`: typing, murmurs, pause, grounding, carrying control and player jump.
- `--quit-after 60 --script tests/imported_character.gd`: both GLBs, normalized weights, rig and pose transitions.

An assertion/error or missing PASS marker means failure. Run the journey test with the native renderer and `-- --capture-journey` to save screenshots of the story beats in `artifacts/`. Character QA follows `references/README.md`; model source editing follows `art/character/README.md`.
