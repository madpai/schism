shader_type canvas_item;
uniform float grime = 0.0;
uniform float fatigue = 0.0;
uniform float injury = 0.0;
void fragment() {
 vec4 color = texture(TEXTURE,UV);
 float cloth = smoothstep(0.22,0.31,UV.y)*(1.0-smoothstep(0.79,0.88,UV.y));
 float stain = step(0.58,fract(sin(dot(floor(UV*95.0),vec2(12.1,39.7)))*984.4));
 color.rgb = mix(color.rgb,color.rgb*vec3(0.65,0.62,0.43),grime*cloth*stain*0.62);
 vec2 face = (UV-vec2(0.489,0.086))*vec2(12.0,38.0);
 float eyes = max(0.0,1.0-length(face));
 color.rgb *= 1.0-eyes*fatigue*0.3;
 float bruise = max(0.0,1.0-length((UV-vec2(0.449,0.103))*vec2(40.0,48.0)));
 color.rgb = mix(color.rgb,vec3(0.23,0.15,0.20),bruise*injury*0.6);
 COLOR = color;
}
