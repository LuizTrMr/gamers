package platform_render

import "base:intrinsics"
import "core:strings"

import "gamers:libs"

debug_show_struct :: proc(s: $T, start_pos: [2]f32, font_size: i32 = 14, background_color: Color = RED, font_color: Color = WHITE)
where intrinsics.type_is_struct(T) {
	padding: [2]f32: 5

	builder := strings.builder_make(context.temp_allocator)
	libs.serialize_to_builder(s, &builder, 0)
	text, err := strings.to_cstring(&builder)
	assert(err == nil)

	size := get_text_size(font_default(), text, f32(font_size))
	draw_rectangle(start_pos.x, start_pos.y, size.x+padding.x*2, size.y, background_color)
	pos := start_pos+padding
	draw_text(font_default(), text, pos.x, pos.y, font_size, font_color)
}
