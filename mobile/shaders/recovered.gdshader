shader_type canvas_item;
uniform float instability = 0.00065;
uniform float degradation = 0.09;
uniform float tracking = 0.035;

float noise(vec2 p) { return fract(sin(dot(p,vec2(12.9898,78.233)))*43758.5453); }
void fragment() {
 vec2 uv = UV;
 float row = floor(uv.y*240.0);
 uv.x += instability*(sin(row*0.7+floor(TIME*7.0))*0.45+sin(TIME*0.9));
 vec4 base = texture(TEXTURE,uv);
 float red = texture(TEXTURE,uv+vec2(instability*0.7,0.0)).r;
 base.r = mix(base.r,red,0.32);
 float grain = noise(floor(uv*vec2(320.0,480.0))+floor(TIME*6.0))-0.5;
 vec3 dithered = floor(clamp(base.rgb+grain/64.0,0.0,1.0)*31.0)/31.0;
 base.rgb = mix(base.rgb,dithered,degradation);
 float scan = sin(uv.y*1500.0)*0.5+0.5;
 base.rgb *= 1.0-tracking*scan;
 float tape = smoothstep(0.995,1.0,sin(uv.y*17.0-TIME*0.11));
 base.rgb += tape*tracking*0.2;
 vec2 vignette = uv*(1.0-uv.yx);
 float edge = pow(clamp(16.0*vignette.x*vignette.y,0.0,1.0),0.12);
 base.rgb *= mix(0.83,1.0,edge);
 COLOR = base;
}
