shader_type canvas_item;
// Generated PNGs contain near-transparent color residue. Keep authored silhouettes.
void fragment() {
 vec4 texel = texture(TEXTURE, UV);
 if (texel.a <= 16.0 / 255.0) { discard; }
 // COLOR already includes the sampled texture and vertex modulation.
}
