shader_type canvas_item;
// Capa a pantalla completa: desenfoca lo que hay dibujado debajo (el fondo de
// la habitación y sus muebles) y lo pasa a la rampa cálida. No usa PNG nuevos.

#include "res://assets/ui/shaders/warm_ramp.gdshaderinc"

uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;
uniform float blur : hint_range(0.0, 6.0) = 3.0;

void fragment() {
	vec3 color = textureLod(screen_texture, SCREEN_UV, blur).rgb;
	COLOR = vec4(warm_ramp(color), 1.0);
}
