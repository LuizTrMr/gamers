#+build js
package platform_render

when RENDER == "CANVAS2D" {
	foreign import "web"
	foreign web {
		// :Setup
		initWindow :: proc "contextless" (width, height: i32) ---

		// :Render
		clearBackground :: proc "contextless" (r, g, b, a: u8) ---
		drawRectangle   :: proc "contextless" (x, y, w, h: f32, r,g,b,a: u8) ---
		drawCircle      :: proc "contextless" (cx, cy: f32, radius: f32, r,g,b,a: u8) ---
		drawLine        :: proc "contextless" (startx, starty, endx, endy: f32, thick: f32, r, g, b, a: u8) ---
		drawTexture     :: proc "contextless" (id: i32, x, y: f32) ---
		drawText        :: proc "contextless" (font: Font, address: [^]byte, len: i32, x, y: f32, font_size: f32, r,g,b,a: u8) ---

	}

	Font :: string
	get_font_default :: proc() -> Font {
		return "Arial"
	}

	Texture :: struct {
		id: i32,
		width, height: i32,
	}

	init_window :: proc(name: string, width, height: i32) {
		// `name` is here for api usage purposes
		initWindow(width, height)
	}

	window_should_close :: proc() -> bool {
		return false
	}

	draw_rectangle :: proc(x, y, w, h: f32, color: Color) {
		drawRectangle(x, y, w, h, to_platform_color(color))
	}

	load_texture :: proc(path: string) -> Texture {
		// TODO
		return {}
	}


	draw_texture :: proc(texture: Texture, x, y: f32, color: Color, rotation: f32 = 0.0, scale: f32 = 1.0) {
		// TODO: color, rotation, scale?
		drawTexture(texture.id, x, y)
	}

	draw_multi_texture :: proc(multi_texture: Multi_Texture, index: i32, x, y: f32, color: Color, rotation: f32 = 0.0, scale: f32 = 1.0) {
		texture_width  := f32(multi_texture.texture.width  / multi_texture.info.cols)
		texture_height := f32(multi_texture.texture.height / multi_texture.info.rows)
		// TODO
	}

	draw_text :: proc(font: Font, text: cstring, x, y: f32, font_size: i32, color: Color) {
		drawText(font, transmute([^]u8)text, cast(i32) len(text), x, y, cast(f32) font_size, to_platform_color(color))
	}

	draw_line :: proc(start, end: [2]f32, thick: f32, color: Color) {
		drawLine(start.x, start.y, end.x, end.y, thick, to_platform_color(color))
	}

	to_platform_color :: #force_inline proc "contextless" (color: Color) -> (r, g, b, a: u8) {
		r = cast(u8)( color.r*255+0.5 )
		g = cast(u8)( color.g*255+0.5 )
		b = cast(u8)( color.b*255+0.5 )
		a = cast(u8)( color.a*255+0.5 )
		return
	}

	clear_background :: proc(color: Color) {
		clearBackground(to_platform_color(color))
	}

	draw_circle :: proc(x, y, radius: f32, color: Color) {
		drawCircle(x, y, radius, to_platform_color(color))
	}

	begin_drawing :: proc() { }
	swap_buffers :: proc() { }
}
