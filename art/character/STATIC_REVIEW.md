# Static model review

Completed before adding the armature. Inspected Blender orthographic front, side and back renders against the supplied three-view screenshots at equal displayed height.

The initial model had a flat chin, visible crown/temple gap, square shoulder caps and incorrectly tilted mittens. Revised the cheek/jaw rings, hair coverage and shoulder caps, then rerendered all views. Corrected the mitten angle in a final static pass and inspected all three resulting images. The final back curtain has an uneven edge and follows the head depth; feet project forward in profile.

The screenshots use perspective and different lighting, so this is a visual reconstruction, not verified original topology or an exact traced model. Static comparisons are saved under artifacts/blender-static-comparison.png. Reference screenshots are study-only and are not exported as textures.


## Existing-mesh sculpt and identity variants

Started from the saved rigged Blender file rather than generating a new body from primitives. Inspected successive static front, side and back renders for both variants. Vertex offsets alone left mechanical shell joins; joining and retopologizing the existing body surfaces removed them. Weights were transferred from those original surfaces and normalized. Reworked the original skull into a rounded, convex facial surface. Broad body facets and genuinely rounded silhouette remain geometry, not a Shade Smooth replacement.

The girl now has a head-covering cloth shell with a neck drape and rounded rectangular glasses. The guy has short waved hair, round glasses and minimal mustache/goatee patches. Both use dot eyes and matte monochrome materials. Fixed forehead/cloth intersections and face-patch clipping found in the static previews. The final face uses blended custom normals to avoid accidental chin markings while retaining body facets.
