# Character reference review

Original source: https://www.youtube.com/watch?v=izKocsEGkv8 by Bryson McBee. Screenshots are local visual study references, not game assets.

- `bryson-front-reference.png`: 1:39, front view carrying the companion head.
- `bryson-body-reference.png`: 10:15, rear view with the original separate companion body in the background.
- Comparison rear view: 8:17, original character facing away, preserved in `bryson-rear-reference.png`.

The reference has simple rounded hands, fuller lower legs and feet, a compact torso, and soft joints. The previous model had narrow ankles, small hands, inward-hanging arms and split surfaces at each knee/elbow. The revision gives arms/legs continuous weighted meshes on two-bone rigs, fuller trouser profiles, larger hands and shoes, a relaxed arm stance and overlapping clothing coverage at the hip. The original screenshot does not expose its topology or rig; ours is a reconstruction, not a claim to the original implementation.

For future character changes, capture the original view and new front/rear/bent-pose renders, compare silhouettes at equal displayed height, inspect joint bending and clothing intersections, fix, and repeat. Preserve the hijab character identity. Screenshots are not to be imported as textures or shipped in an exported game.

Current palette follows the requested black-and-white reference treatment: pale skin and clothing, black hair/hijab and facial details. Face geometry and the girl’s glasses remain. Neutral lighting avoids a warm or blue cast on these materials.


November 1 body and movement repair: compared the five user-provided front/rear/side images and the 10.98-second, 60 fps movement clip. Sampled the full clip and 0.1-second steps during 3.4–4.5 seconds. Limbs now taper continuously toward wrists/ankles, without the previous calf bulge and knee pinch. Removed the separate hip ridge, flattened the shirt hem, opened the resting arm stance and enlarged hands. Knee recovery now follows the returning leg, with opposite arms, distance-driven phase, eased stopping and smaller body bob. This is a reconstruction from visible poses, not the original rig.

Run `Godot_v4.7.2-stable_win64_console.exe --headless --path . --quit-after 60 --script tests/character_shape.gd` to check actual generated mesh taper and alternating knee recovery. `-- --capture=characters-motion` renders 24 poses through the production animation function, alongside the existing front/rear/side capture modes.
