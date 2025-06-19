shader_type canvas_item;

uniform float fill : hint_range(0.0, 2.0) = 0.0;
uniform float flatten : hint_range(0.0, 1.0) = 0.0;
uniform int mode = 1;
uniform float size_scale : hint_range(1.0, 30.0) = 4.0;
uniform float peak_sharpness : hint_range(1.0, 5.0) = 2.5;
uniform vec4 coffee_color : source_color = vec4(0.4, 0.3, 0.2, 1.0);
uniform float texture_scale : hint_range(1.0, 32.0) = 16.0; // Nuevo uniforme para controlar la escala

void fragment() {
    vec2 uv = (UV - vec2(0.5)) * 2.0;
    uv /= size_scale * 0.5;  // Ajuste de escala
    
    // Factores de forma
    float width = (mode == 1) ? 1.8 : 2.5;
    float height = (mode == 1) ? 3.0 : 10.0;
    
    // Distancia con forma controlada
    float radius_x = abs(uv.x) * width;
    float radius_y = uv.y * height;
    
    // Forma del montículo
    float mound;
    if (radius_y > 0.0) {
        mound = exp(pow(radius_x, 2.0) - pow(radius_y * 1.5, 2.0));
    } else {
        mound = exp(pow(radius_x, 0.3));
    }
    
    // Aplicar fill y flatten
    float adjusted_fill = fill;
    if (fill > 1.0) {
       adjusted_fill = 1.0 + (fill - 1.0) * (1.0 - flatten * 0.7);
    }
    
    if (mound > 0.0 && mound <= adjusted_fill) {
        // Textura granular de mayor resolución (256x256)
        vec2 noise_uv = uv * texture_scale; // Escalar las coordenadas para el ruido
        float grain = fract(sin(dot(noise_uv, vec2(12.9898, 78.233))) * 43758.5453);
        
        // Añadir más octavas de ruido para mayor detalle
        grain += 0.5 * fract(sin(dot(noise_uv * 2.0, vec2(89.42, 191.63))) * 59739.5453);
        grain *= 0.6667; // Normalizar
        
        vec3 color = coffee_color.rgb * mix(0.8, 1.2, grain * 0.4); // Ajustar contraste
        color *= mix(0.7, 1.3, pow(mound/adjusted_fill, 0.5));
        
        COLOR = vec4(color, coffee_color.a);
    } else {
        discard;
    }
}