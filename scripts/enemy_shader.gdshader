shader_type canvas_item;

uniform vec4 target_colors[8] : source_color;
uniform vec4 replace_colors[8] : source_color;
uniform int color_count = 2; // How many colors to check in the palette
uniform float tolerance : hint_range(0.0, 1.0) = 0.1;

void fragment() {
    vec4 tex_color = texture(TEXTURE, UV);

    for (int i = 0; i < color_count; i++) {
        if (distance(tex_color.rgb, target_colors[i].rgb) < tolerance) {
            tex_color.rgb = replace_colors[i].rgb;
            break; // Stop at the first match
        }
    }

    COLOR = tex_color;
}
