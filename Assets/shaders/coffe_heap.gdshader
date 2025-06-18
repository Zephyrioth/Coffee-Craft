shader_type canvas_item;

uniform float fill : hint_range(0.0, 2.0) = 0.0;
uniform float flatten : hint_range(0.0, 1.0) = 0.0;
uniform int mode = 1;
uniform float size_scale : hint_range(1.0, 10.0) = 4.0;
uniform float peak_sharpness : hint_range(1.0, 5.0) = 2.5;
uniform vec4 coffee_color : source_color = vec4(0.4, 0.3, 0.2, 1.0);

void fragment() {
    vec2 uv = (UV - vec2(0.5)) * 2.0;
    uv /= size_scale * 0.5;  // Ajuste de escala
    
    // Factores de forma
    float width = (mode == 1) ? 1.8 : 2.5;  // Más ancho en mesa
    float height = (mode == 1) ? 3.0 : 2.0; // Más alto en portafiltro
    
    // Distancia con forma controlada (plana abajo, puntiaguda arriba)
    float radius_x = abs(uv.x) * width;
    float radius_y = uv.y * height;
    
    // Forma del montículo (plano en la base)
    float mound;
    if (radius_y > 0.0) {
        // Parte superior (pico)
        mound = exp(-pow(radius_x, 2.0) - pow(radius_y * 1.5, 2.0));
    } else {
        // Parte inferior (plana)
        mound = exp(-pow(radius_x, 2.0));
    }
    
    // Aplicar fill y flatten
    float adjusted_fill = fill;
    if (fill > 1.0) {
        adjusted_fill = 1.0 + (fill - 1.0) * (1.0 - flatten * 0.7);
    }
    
    // Mostrar sólo lo que corresponde
    if (mound > 0.0 && mound <= adjusted_fill * 1.1) {
        // Textura granular
        float grain = fract(sin(dot(uv, vec2(12.9898, 78.233))) * 43758.5453);
        vec3 color = coffee_color.rgb * mix(0.8, 1.2, grain * 0.3);
        
        // Sombreado para dar profundidad
        color *= mix(0.7, 1.3, pow(mound/adjusted_fill, 0.5));
        
        COLOR = vec4(color, coffee_color.a);
    } else {
        discard;
    }
}