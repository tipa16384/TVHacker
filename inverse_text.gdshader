shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, filter_nearest;

uniform vec3 dark_text = vec3(0.0, 0.0625, 0.0); // #001000
uniform vec3 light_text = vec3(0.0, 1.0, 0.333); // CRT green
uniform float threshold = 0.45;

void fragment() {
    vec4 screen_color = texture(screen_texture, SCREEN_UV);
    vec4 texture_color = texture(TEXTURE, UV);

    float brightness = dot(screen_color.rgb, vec3(0.299, 0.587, 0.114));

    vec3 text_color = brightness > threshold ? dark_text : light_text;

    COLOR = vec4(text_color, texture_color.a);
}