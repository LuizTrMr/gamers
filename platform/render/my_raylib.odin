package platform_render

import "core:testing"
import "core:fmt"

import rl "vendor:raylib"

import mm  "../../my_math"

when PLATFORM == "RAYLIB" {
	Texture :: rl.Texture
	Font    :: rl.Font
	Shader  :: rl.Shader

	swap_buffers :: proc() {
		rl.EndDrawing()
	}

	load_texture :: proc(path: string) -> Texture {
		return rl.LoadTexture( cstring(raw_data(path)) )
	}

	load_font :: proc(path: string) -> Font {
		return rl.LoadFont( cstring(raw_data(path)) )
	}

	load_shader :: proc(vertex_path, fragment_path: string) -> Shader {
		return rl.LoadShader(cstring(raw_data(vertex_path)), cstring(raw_data(fragment_path)))
	}

	to_raylib_color :: #force_inline proc "contextless" (color: Color) -> rl.Color {
		return {
			cast(u8)( color.r*255+0.5 ),
			cast(u8)( color.g*255+0.5 ),
			cast(u8)( color.b*255+0.5 ),
			cast(u8)( color.a*255+0.5 ),
		}
	}

	@(test)
	to_raylib_color_test :: proc(t: ^testing.T) {
		testing.expect(t, to_raylib_color(BLUE) == rl.BLUE, "my BLUE is not equal to rl.BLUE")
	}

	clear_background :: proc(color: Color) {
		rl.ClearBackground(to_raylib_color(color))
	}

	draw_text :: proc(font: rl.Font, text: cstring, x, y: f32, font_size: i32, color: Color) {
		rl.DrawTextEx(font, text, rl.Vector2{x, y}, f32(font_size), 1.0, to_raylib_color(color))
	}

	draw_texture :: proc(texture: Texture, x, y: f32, color: Color, rotation: f32 = 0.0, scale: f32 = 1.0) {
		texture_width  := f32(texture.width)
		texture_height := f32(texture.height)

		half_width  := texture_width  * 0.5 * scale
		half_height := texture_height * 0.5 * scale
		src    := rl.Rectangle{0, 0, texture_width, texture_height}
		dst    := rl.Rectangle{x+half_width, y+half_height, texture_width*scale, texture_height*scale}
		origin := rl.Vector2{half_width, half_height}

		rl.DrawTexturePro(texture, src, dst, origin, rotation, to_raylib_color(color)) // NOTE: Using `Pro` for rotating the sprite around its center
	}

	draw_texture_by_center :: proc(texture: Texture, center: mm.V2, color: Color, rotation: f32 = 0.0, scale: f32 = 1.0) {
		texture_width  := f32(texture.width)
		texture_height := f32(texture.height)

		half_width  := texture_width  * 0.5 * scale
		half_height := texture_height * 0.5 * scale
		src    := rl.Rectangle{0, 0, texture_width, texture_height}
		dst    := rl.Rectangle{center.x, center.y, texture_width*scale, texture_height*scale}
		origin := rl.Vector2{half_width, half_height}
		rl.DrawTexturePro(texture, src, dst, origin, rotation, to_raylib_color(color)) // NOTE: Using `Pro` for rotating the sprite around its center
	}

	draw_texture_to_rect :: proc(texture: Texture, pos, size: mm.V2, color: Color, rotation: f32 = 0.0, scale: f32 = 1.0) {
		half_width  := size.x * 0.5 * scale
		half_height := size.y * 0.5 * scale
		src    := rl.Rectangle{0, 0, size.x, size.y}
		dst    := rl.Rectangle{pos.x+half_width, pos.y+half_height, size.x, size.y}
		origin := rl.Vector2{half_width, half_height}
		rl.DrawTexturePro(texture, src, dst, origin, rotation, to_raylib_color(color)) // NOTE: Using `Pro` for rotating the sprite around its center
	}
	
	draw_multi_texture :: proc(multi_texture: Multi_Texture, index: i32, x, y: f32, color: Color, rotation: f32 = 0.0, scale: f32 = 1.0) {
		texture_width  := f32(multi_texture.texture.width  / multi_texture.info.cols)
		texture_height := f32(multi_texture.texture.height / multi_texture.info.rows)

		half_width  := texture_width  * 0.5 * scale
		half_height := texture_height * 0.5 * scale

		grid_x := f32(index % multi_texture.info.cols)
		grid_y := f32(index / multi_texture.info.cols)

		src    := rl.Rectangle{grid_x*texture_width, grid_y*texture_height, texture_width, texture_height}
		dst    := rl.Rectangle{x+half_width, y+half_height, texture_width*scale, texture_height*scale}
		origin := rl.Vector2{half_width, half_height}

		rl.DrawTexturePro(multi_texture.texture, src, dst, origin, rotation, to_raylib_color(color))
	}

	draw_rectangle :: proc(x, y, w, h: f32, color: Color) {
		rl.DrawRectangleV(rl.Vector2{x,y}, rl.Vector2{w,h}, to_raylib_color(color))
	}

	draw_line :: proc(start, end: mm.V2, thick: f32, color: Color) {
		rl.DrawLineEx(start, end, thick, to_raylib_color(color))
	}

	draw_rectangle_lines :: proc(pos, size: mm.V2, thick: f32, color: Color) {
		rec := rl.Rectangle{
			pos.x ,
			pos.y ,
			size.x,
			size.y,
		}
		rl.DrawRectangleLinesEx(rec, thick, to_raylib_color(color))
	}

	draw_circle :: proc(x, y, radius: f32, color: Color) {
		rl.DrawCircleV({x,y}, radius, to_raylib_color(color))
	}
}
