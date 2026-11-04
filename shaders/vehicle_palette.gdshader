shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;

uniform sampler2D palette_texture : source_color, filter_nearest_mipmap;
uniform float color_tolerance : hint_range(0.0, 0.5, 0.01) = 0.08;
instance uniform vec4 car_color : source_color = vec4(1.0, 0.752941, 0.266667, 1.0);

const vec3 SOURCE_BODY_COLOR = vec3(1.0, 0.527115, 0.057805);
void fragment() {
	vec4 palette_color = texture(palette_texture, UV);
	float color_distance = distance(palette_color.rgb, SOURCE_BODY_COLOR);
	float body_mask = 1.0 - smoothstep(color_tolerance, color_tolerance * 2.0, color_distance);

	ALBEDO = mix(palette_color.rgb, car_color.rgb, body_mask);
	ROUGHNESS = 1.0;
	METALLIC = 0.0;
	ALPHA = palette_color.a;
}
