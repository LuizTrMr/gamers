#+build !js
package platform_render

import "core:fmt"
import "core:strings"

import rl "vendor:raylib"

import mm  "../../my_math"

Texture :: rl.Texture
Font    :: rl.Font
Shader  :: rl.Shader

font_default :: proc() -> Font {
	return rl.GetFontDefault()
}

begin_drawing :: proc() {
	rl.BeginDrawing()
}

window_should_close :: proc() -> bool {
	return rl.WindowShouldClose()
}

swap_buffers :: proc() {
	rl.EndDrawing()
}

init_window :: proc(name: string, width, height: i32) {
	rl.InitWindow(width, height, cstring(raw_data(name)))
}

load_texture :: proc(path: string) -> Texture {
	return rl.LoadTexture( cstring(raw_data(path)) )
}

load_texture_from_memory :: proc(memory: []byte) -> Texture {
	img := rl.LoadImageFromMemory(".png", raw_data(memory), cast(i32)len(memory))
	tex := rl.LoadTextureFromImage(img)
	rl.UnloadImage(img)
	return tex
}

load_font :: proc(path: string) -> Font {
	return rl.LoadFont( cstring(raw_data(path)) )
}

load_shader :: proc(vertex_path, fragment_path: cstring) -> Shader {
	return rl.LoadShader(vertex_path, fragment_path)
}


clear_background :: proc(color: Color) {
	rl.ClearBackground(to_raylib_color(color))
}

draw_text :: proc(font: Font, text: cstring, x, y: f32, font_size: i32, color: Color) {
	rl.DrawTextEx(font, text, rl.Vector2{x, y}, f32(font_size), 1.0, to_raylib_color(color))
}

get_text_size :: proc(font: Font, text: cstring, font_size: f32) -> mm.V2 {
	return rl.MeasureTextEx(font, text, font_size, 1.0) // NOTE: Default spacing = 1.0 (Taken from here: https://github.com/raysan5/raylib/blob/44659b7ba8bd6d517d75fac8675ecd026f713240/src/rtext.c#L1207)
}

draw_texture :: proc(texture: Texture, x, y: f32, color: Color, rotation: f32 = 0.0, scale: f32 = 1.0,
					 flip_x := false, flip_y := false) {
	texture_width  := f32(texture.width)
	texture_height := f32(texture.height)

	if flip_x do texture_width  = -texture_width
	if flip_y do texture_height = -texture_height

	half_width  := texture_width  * 0.5 * scale
	half_height := texture_height * 0.5 * scale
	src    := rl.Rectangle{0, 0, texture_width, texture_height}
	dst    := rl.Rectangle{x+half_width, y+half_height, texture_width*scale, texture_height*scale}
	origin := rl.Vector2{half_width, half_height}

	rl.DrawTexturePro(texture, src, dst, origin, rotation, to_raylib_color(color)) // NOTE: Using `Pro` for rotating the sprite around its center
}

draw_texture_by_center :: proc(texture: Texture, center: mm.V2, color: Color, rotation: f32 = 0.0, scale: f32 = 1.0,
							   flip_x := false, flip_y := false) {
	texture_width  := f32(texture.width)
	texture_height := f32(texture.height)

	if flip_x do texture_width  = -texture_width
	if flip_y do texture_height = -texture_height

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

draw_rectangle_by_center :: proc(center: mm.V2, w, h: f32, color: Color) {
	rl.DrawRectangleV(center-{w,h}/2, rl.Vector2{w,h}, to_raylib_color(color))
}

draw_rectangle_rotated :: proc(x, y, w, h: f32, color: Color, rotation: f32, pivot: Pivot) {
	offset: [2]f32
	switch pivot {
		case .top_left     : offset = 0
		case .top_center   : offset = {0.5, 0}
		case .top_right    : offset = {1, 0}
		case .mid_left     : offset = {0,0.5}
		case .center       : offset = {0.5,0.5}
		case .mid_right    : offset = {1,0.5}
		case .bottom_left  : offset = {0,1}
		case .bottom_center: offset = {0.5,1}
		case .bottom_right : offset = {1,1}
	}
	origin := [2]f32{w,h} * offset

	rect := rl.Rectangle{x, y, w, h}
	rl.DrawRectanglePro(rect, origin, rotation, to_raylib_color(color))
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

to_raylib_color :: #force_inline proc "contextless" (color: Color) -> rl.Color {
	return {
		cast(u8)( color.r*255+0.5 ),
		cast(u8)( color.g*255+0.5 ),
		cast(u8)( color.b*255+0.5 ),
		cast(u8)( color.a*255+0.5 ),
	}
}
