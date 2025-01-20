package platform_render

when PLATFORM == "CANVAS2D" {
	foreign import "web"

	foreign web {
		clearBackground :: proc "contextless" (r, g, b, a: u8) ---
		drawCircle      :: proc "contextless" (cx, cy: f32, radius: f32, r,g,b,a: u8) ---
		drawTexture     :: proc "contextless" (id: i32, x, y: f32) ---

	}

	Texture :: struct {
		id: i32,
		width, height: i32,
	}

	to_platform_color :: #force_inline proc "contextless" (color: Color) -> (r, b, g, a: u8) {
		r = cast(u8)( color.r*255+0.5 )
		g = cast(u8)( color.g*255+0.5 )
		b = cast(u8)( color.b*255+0.5 )
		a = cast(u8)( color.a*255+0.5 )
		return
	}

	clear_background :: proc(color: Color) {
		clearBackground(to_platform_color(color))
	}

	draw_multi_texture :: proc(multi_texture: Multi_Texture, index: i32, x, y: f32, color: Color, rotation: f32 = 0.0, scale: f32 = 1.0) {
	}

}
