// Rampa cálida: lleva la luminancia de un color a tonos crema, durazno y café.
// La comparten warm_backdrop (fondo desenfocado) y warm_tint (alfombra).
uniform vec4 ramp_dark : source_color = vec4(0.541, 0.369, 0.235, 1.0);   // café tierra
uniform vec4 ramp_mid : source_color = vec4(0.910, 0.769, 0.604, 1.0);    // durazno
uniform vec4 ramp_light : source_color = vec4(0.984, 0.941, 0.871, 1.0);  // crema
uniform float ramp_strength : hint_range(0.0, 1.0) = 0.9;

vec3 warm_ramp(vec3 color) {
	float l = dot(color, vec3(0.299, 0.587, 0.114));
	vec3 warm = l < 0.75
		? mix(ramp_dark.rgb, ramp_mid.rgb, smoothstep(0.4, 0.75, l))
		: mix(ramp_mid.rgb, ramp_light.rgb, smoothstep(0.75, 0.95, l));
	return mix(color, warm, ramp_strength);
}
