shader_type canvas_item;

uniform bool enabled;
uniform vec4 colour : source_color;

void fragment() {
	if (enabled == true) {
		COLOR.rgb = colour.rgb;
		COLOR.a *= colour.a;
		}
}
