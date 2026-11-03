# Static character review

The comparisons use matching orthographic front, side and back camera angles. Each character is cropped to its visible silhouette and displayed at the same height. Left is the committed baseline; right is this static refinement. These images are our own Blender renders. Third-party study screenshots remain outside the published assets.

- [Body comparison](body-before-after.png)
- [Clothed comparison](outfit-before-after.png)

The pass reshapes the existing control cages: a slightly uneven compact torso, fuller upper-arm silhouette, irregular mitten palms, nonuniform leg profiles and shoes with a distinct heel, toe box and sole. The ten body modules stay independent. Identity meshes, bone rest matrices and body vertex/face counts are unchanged against the baseline. The established head proportion is retained.

Validation uses `art/character/validate_static_revision.py`, `validate_modules.py`, Godot's imported-character checks and the static-only capture path in `tests/soft_visuals.gd`. Walking, jumping and throwing code is unchanged. A coordinated walk cycle remains a separate task after this static review.
