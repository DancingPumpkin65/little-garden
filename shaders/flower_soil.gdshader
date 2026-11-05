shader_type spatial;
render_mode cull_disabled;
uniform vec4 tint : source_color = vec4(1.0);
uniform float soil_height = 0.0;
varying float world_height;
void vertex() {
	world_height = (MODEL_MATRIX * vec4(VERTEX, 1.0)).y;
}
void fragment() {
	if (world_height < soil_height + 0.003) discard;
	ALBEDO = tint.rgb;
	ROUGHNESS = 1.0;
}
