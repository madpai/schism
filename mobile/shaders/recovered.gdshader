shader_type canvas_item;
uniform float instability = 0.00065;
uniform float degradation = 0.09;
uniform float tracking = 0.035;
uniform sampler2D full_cart : filter_nearest;
uniform float cart_remaining = -1.0;
uniform vec4 cart_rect = vec4(0.0,0.52,0.34,0.29);
uniform bool running = false;
uniform float motion = 1.0;
uniform vec2 drum_center = vec2(0.585,0.468);
uniform vec2 drum_radius = vec2(0.122,0.081);

float noise(vec2 p) { return fract(sin(dot(p,vec2(12.9898,78.233)))*43758.5453); }
void fragment() {
 vec2 uv = UV;
 float row = floor(uv.y*240.0);
 uv.x += instability*(sin(row*0.7+floor(TIME*7.0))*0.45+sin(TIME*0.9));
 vec4 base = texture(TEXTURE,uv);
 if (cart_remaining > 0.0 && uv.x >= cart_rect.x && uv.x < cart_rect.x+cart_rect.z && uv.y > cart_rect.y && uv.y < cart_rect.y+cart_rect.w) {
  float edge = cart_rect.x+cart_rect.z*cart_remaining/4.0;
  float pile = 1.0-smoothstep(edge-0.002,edge+0.002,uv.x);
  base = mix(base,texture(full_cart,uv),pile);
 }
 if (running && motion > 0.0) {
  vec2 local = (uv-drum_center)/drum_radius;
  float glass = 1.0-smoothstep(0.84,0.96,length(local));
  float angle = TIME*1.7;
  mat2 rotation = mat2(vec2(cos(angle),sin(angle)),vec2(-sin(angle),cos(angle)));
  vec2 turning = drum_center+(rotation*local)*drum_radius;
  base = mix(base,texture(TEXTURE,turning),glass*0.72);
 }
 float red = texture(TEXTURE,uv+vec2(instability*0.7,0.0)).r;
 base.r = mix(base.r,red,instability>0.0 ? 0.10 : 0.0);
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
