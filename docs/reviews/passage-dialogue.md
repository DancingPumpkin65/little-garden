# Passage dialogue revision

The first passage starts with "Had lpassage twil... b7al tri9 dyalk lkhadma!". The stairs joke and garden photo-spot comment are removed.

The second passage has its own progress counter, so the first passage cannot exhaust its lines. After the door dialogue finishes, three quiet seconds start "Yak ssaliti l3cha!? •ᴗ•". Another quiet pause follows before "Maghadich na3tik lmcha dyali! /•᷅‎‎•᷄\੭". Story dialogue always takes priority.

The formerly repeated smile remains in the opening greeting. Other lines use expressions suited to encouragement, celebration, teasing and affection.

Validation: `tests/passage_dialogue.gd` reproduced the silent second passage before the fix and now verifies both lines despite exhausted first-passage progress. `tests/interlude_ui.gd` and `tests/reunion_cake.gd` pass, including the updated door greeting and full birthday/restart flow.
