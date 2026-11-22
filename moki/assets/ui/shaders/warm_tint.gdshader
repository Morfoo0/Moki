shader_type canvas_item;
// Pasa los colores de una textura a la rampa cálida, conservando su alfa
// (p. ej. la alfombra de la habitación en tonos tierra y crema).

#include "res://assets/ui/shaders/warm_ramp.gdshaderinc"

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	COLOR = vec4(warm_ramp(tex.rgb), tex.a);
}
