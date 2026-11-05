shader_type spatial;
uniform vec4 cloth_color : source_color = vec4(1.0);
uniform float reveal : hint_range(0.0,1.0) = 0.0;
uniform bool incoming = true;
void fragment() {
 float grain = fract(sin(dot(floor(FRAGCOORD.xy),vec2(12.9898,78.233)))*43758.5453);
 if (incoming ? grain >= reveal : grain < reveal) discard;
 ALBEDO = cloth_color.rgb;
 ROUGHNESS = 1.0;
 SPECULAR = 0.0;
}
