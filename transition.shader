shader_type canvas_item;
render_mode unshaded;
 
uniform float delta : hint_range(0.0, 1.0);
uniform sampler2D t1;
uniform sampler2D t2;
uniform vec2 t2s = vec2(1, 1);
uniform vec2 pos = vec2(100, 100);
//uniform vec4 outline_color : hint_color;

varying vec2 t2c;

void vertex()
{
    t2c = UV;
}

void fragment()
{
    vec2 newuv = UV;
    newuv.x += pos.x;
    newuv.y += pos.y;
    vec4 color_a = texture(TEXTURE, newuv);
    vec4 color_b = texture(t2, UV);
    COLOR = mix(color_a, color_b, delta);
}