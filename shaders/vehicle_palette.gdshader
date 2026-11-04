shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;

uniform sampler2D palette_texture : source_color, filter_nearest_mipmap;
uniform float color_tolerance : hint_range(0.0, 1.0, 0.01) = 0.35; // Wider tolerance baseline
uniform vec4 car_color : source_color = vec4(1.0, 0.0, 0.0, 1.0); 

const vec3 SOURCE_BODY_COLOR = vec3(1.0, 0.527115, 0.057805);

void fragment() {
	vec4 palette_color = texture(palette_texture, UV);
	
	// --- BROAD COHESIVE MASK ---
	// Instead of a tiny color distance window, we check if the texture pixel is 
	// primarily "Warm/Orange/Red" by verifying if Red outweighs Blue significantly.
	float warm_factor = clamp(palette_color.r - palette_color.b, 0.0, 1.0);
	
	// Fallback to structural distance check just in case, but with a highly permissive curve
	float color_dist = distance(palette_color.rgb, SOURCE_BODY_COLOR);
	float strict_mask = 1.0 - smoothstep(color_tolerance, color_tolerance * 1.8, color_dist);
	
	// Combine both masks so compressed textures or slight color shifts never break it again
	float body_mask = max(warm_factor * 0.8, strict_mask);

	// Protect absolute dark gray/black/white details (wheels, windshield, chassis) from bleeding color
	float saturation = max(max(palette_color.r, palette_color.g), palette_color.b) - min(min(palette_color.r, palette_color.g), palette_color.b);
	if (saturation < 0.15) {
		body_mask = 0.0;
	}

	// Capture shadows and lighting shapes baked into the original texture skin
	float shadow_factor = dot(palette_color.rgb, vec3(0.299, 0.587, 0.114));
	shadow_factor = clamp(shadow_factor * 1.3, 0.1, 1.0); // Never allow absolute zero blackouts except on panel gaps

	// Process paint layers cleanly
	vec3 vibrant_paint = car_color.rgb * shadow_factor;

	// Render output mixing
	ALBEDO = mix(palette_color.rgb, vibrant_paint, body_mask);
	
	// Professional High-Gloss clear coat finish
	ROUGHNESS = 0.18; 
	METALLIC = 0.75;
	ALPHA = palette_color.a;
}
