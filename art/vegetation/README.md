# Rounded vegetation library

`build_library.py` authors `rounded_library.blend` through custom vertices, branching control edges and local canopy unions. It creates oak, plum, willow and evergreen wood/crown pairs, a bush, a broad leaf, a petal volume and a curved thick stem. Crowns are cohesive rounded masses. The trunk fork surfaces are relaxed and simplified before one level of silhouette subdivision.

Run the script without arguments for master-asset renders in `artifacts/vegetation-review/`. Inspect those first, then run with `-- --export` to create `assets/vegetation/rounded_library.glb`. `GardenVegetationAssets` shares imported meshes across the scene. Tree variation comes from species, rotation, proportion and color; it does not require thousands of tiny individual petals.

Flowers keep fixed roots. Their stems extend, leaves unfold and petal hinges open. Ground plants use the same rounded leaf geometry. Perimeter bushes have collision behind the foliage. The existing birthday reveal, blue cloud sky and walking flower trail are preserved.
