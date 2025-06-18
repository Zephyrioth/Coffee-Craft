shader_type canvas_item;

uniform float fill : hint_range(0.0, 1.0) = 1.0;
uniform sampler2D mask_texture;

void fragment() {
    vec4 tex_color = texture(TEXTURE, UV);
    float mask_val = texture(mask_texture, UV).r;

    if (mask_val < fill) {
        discard;
    } else {
        COLOR = tex_color;
    }
}
