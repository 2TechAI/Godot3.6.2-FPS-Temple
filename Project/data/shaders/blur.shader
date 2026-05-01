shader_type canvas_item;

uniform float blur_amount : hint_range(0.0, 5.0) = 2.0;

void fragment() {
	vec4 color = vec4(0.0);
	float total = 0.0;
	
	for (float x = -2.0; x <= 2.0; x += 1.0) {
		for (float y = -2.0; y <= 2.0; y += 1.0) {
			vec2 offset = vec2(x, y) * blur_amount * SCREEN_PIXEL_SIZE;
			color += texture(SCREEN_TEXTURE, SCREEN_UV + offset);
			total += 1.0;
		}
	}
	
	COLOR = color / total;
	COLOR.a = 0.92;
}
