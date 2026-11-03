shader_type sky;
uniform float reveal = 0.0;
float hash(vec2 p){return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);}
float noise(vec2 p){vec2 i=floor(p);vec2 f=fract(p);f=f*f*(3.0-2.0*f);return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1)),f.x),f.y);}
void sky(){
 float up=max(EYEDIR.y,0.0);
 vec3 blue=mix(vec3(0.63,0.83,0.97),vec3(0.18,0.49,0.83),pow(up,0.55));
 vec2 p=EYEDIR.xz/max(EYEDIR.y+0.65,0.2)*2.4+vec2(TIME*0.008,0.0);
 float cloud=noise(p)*0.58+noise(p*2.1)*0.28+noise(p*4.3)*0.14;
 float cover=smoothstep(0.43,0.63,cloud)*smoothstep(-0.6,-0.15,EYEDIR.y);
 vec3 shade=mix(vec3(0.83,0.88,0.94),vec3(1.0),smoothstep(0.48,0.77,cloud));
 COLOR=mix(vec3(0.0),mix(blue,shade,cover),reveal);
}
