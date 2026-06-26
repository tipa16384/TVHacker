shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, filter_nearest;

float random (vec2 uv) {
    return fract(sin(dot(uv.xy,
        vec2(12.9898,78.233))) * 43758.5453123);
}

void fragment() {
    vec4 screen_color = texture(screen_texture, SCREEN_UV);
    vec4 texture_color = texture(TEXTURE, UV);

    float brightness = dot(texture_color.rgb, vec3(0.299, 0.587, 0.114));
	
	float sinval = (sin(100.0 * TAU * UV.y) + 1.0) / 4.0 + 0.5;

    COLOR = vec4(0.0, brightness * sinval, 0.0, texture_color.a);
}
