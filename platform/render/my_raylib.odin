#+build !js
package platform_render

import "core:fmt"
import "core:strings"

import rl "vendor:raylib"
import gl "vendor:OpenGL"

import mm  "../../my_math"

Texture :: rl.Texture
Font    :: rl.Font

font_default :: proc() -> Font {
	return rl.GetFontDefault()
}

begin_drawing :: proc() {
	rl.BeginDrawing()
}

to_platform_camera :: proc(camera: Camera2D) -> (res: rl.Camera2D) {
	res.offset = -camera.position
	res.target =  camera.target
	res.zoom   =  camera.zoom
	return
}

_camera2d_begin :: proc(camera: Camera2D) {
	rl.BeginMode2D(to_platform_camera(camera))
}

_camera2d_end :: proc() {
	rl.EndMode2D()
}

_camera2d_screen_to_world_position :: #force_inline proc(mouse_position: [2]f32, camera: Camera2D) -> mm.V2 {
	return rl.GetScreenToWorld2D(mouse_position, to_platform_camera(camera))
}

_set_mouse_cursor :: #force_inline proc "contextless" (opt: Option) {
	switch opt {
	case .enabled : rl.EnableCursor()
	case .disabled: rl.DisableCursor()
	}
}

swap_buffers :: proc() {
	rl.EndDrawing()
}

init_window :: proc(name: string, width, height: i32) {
	rl.InitWindow(width, height, cstring(raw_data(name)))
}
close_window :: proc() {
	rl.CloseWindow()
}
window_should_close :: proc() -> bool {
	return rl.WindowShouldClose()
}

set_window_size :: proc(width, height: i32) {
	rl.SetWindowSize(width, height)
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

raylib_image_to_image :: proc(rlimg: rl.Image) -> (res:Image) {
	res.data   = rlimg.data
	res.width  = rlimg.width
	res.height = rlimg.width
	#partial switch rlimg.format {
	case .UNCOMPRESSED_R8G8B8   : res.format = .RGB8
	case .UNCOMPRESSED_R8G8B8A8 : res.format = .RGBA8
	case .UNCOMPRESSED_GRAYSCALE: res.format = .R8
	case:
		assert(false, "Ixi")
	}
	return
}

load_image :: proc(path: string) -> Image {
	rlimg := rl.LoadImage( cstring(raw_data(path)) )
	return raylib_image_to_image(rlimg)
}

_load_image_from_texture :: proc(texture: Texture) -> Image {
	rlimg := rl.LoadImageFromTexture(texture)
	return raylib_image_to_image(rlimg)
}

load_font :: proc(path: string) -> Font {
	return rl.LoadFont( cstring(raw_data(path)) )
}

load_shader :: proc(vertex_path, fragment_path: cstring) -> Shader {
	return rl.LoadShader(vertex_path, fragment_path)
}

_clear :: proc(options: bit_set[Clear_Option], color: Color) {
	if .Color in options {
		rl.ClearBackground(to_raylib_color(color))
	}
	if .Stencil in options {
		gl.Clear(gl.STENCIL_BUFFER_BIT)
	}
}
clear_background :: proc(color: Color) {
	rl.ClearBackground(to_raylib_color(color))
}

draw_text :: proc(font: Font, text: cstring, x, y: f32, font_size: i32, color: Color) {
	rl.DrawTextEx(font, text, rl.Vector2{x, y}, f32(font_size), 1.0, to_raylib_color(color))
}

draw_text_by_center :: proc(font: Font, text: cstring, center: [2]f32, font_size: i32, color: Color, rotation: f32 = 0.0, scale: f32 = 1.0) {
	text_size := get_text_size(font, text, f32(font_size))

	half_width  := text_size.x * 0.5 * scale
	half_height := text_size.y * 0.5 * scale
	src    := rl.Rectangle{0, 0, text_size.x, text_size.y}
	dst    := rl.Rectangle{center.x, center.y, text_size.x*scale, text_size.y*scale}
	origin := rl.Vector2{half_width, half_height}

	rl.DrawTextPro(font, text, center, origin, rotation, f32(font_size), scale, to_raylib_color(color))
}

get_text_size :: proc(font: Font, text: cstring, font_size: f32) -> [2]f32 {
	return rl.MeasureTextEx(font, text, font_size, 1.0) // NOTE: Default spacing = 1.0 (Taken from here: https://github.com/raysan5/raylib/blob/44659b7ba8bd6d517d75fac8675ecd026f713240/src/rtext.c#L1207)
}

draw_texture_rectangle :: proc(texture: Texture, x, y: f32, rectangle: Rectangle, color: Color = WHITE) {
	rl.DrawTextureRec(texture,
					  {rectangle.x, rectangle.y, rectangle.width, rectangle.height},
					  {x, y},
					  to_raylib_color(color))
}

draw_texture_f32 :: proc(texture: Texture, x, y: f32, color: Color = WHITE, rotation: f32 = 0.0, scale: f32 = 1.0,
					 flip_x := false, flip_y := false, loc := #caller_location) {
	assert(rl.IsTextureValid(texture), loc=loc)
	assert(rl.IsTextureReady(texture), loc=loc)
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
draw_texture_v2 :: proc(texture: Texture, pos: mm.V2, color: Color = WHITE, rotation: f32 = 0.0, scale: f32 = 1.0) {
	draw_texture_f32(texture, pos.x, pos.y, color, rotation, scale)
}
draw_texture :: proc{draw_texture_f32, draw_texture_v2}

draw_texture_by_center :: proc(texture: Texture, center: mm.V2, color: Color = WHITE, rotation: f32 = 0.0, scale: f32 = 1.0,
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

draw_texture_to_rect :: proc(texture: Texture, pos, size: mm.V2, color: Color = WHITE, rotation: f32 = 0.0, scale: f32 = 1.0) {
	half_width  := size.x * 0.5 * scale
	half_height := size.y * 0.5 * scale
	src    := rl.Rectangle{0, 0, size.x, size.y}
	dst    := rl.Rectangle{pos.x+half_width, pos.y+half_height, size.x, size.y}
	origin := rl.Vector2{half_width, half_height}
	rl.DrawTexturePro(texture, src, dst, origin, rotation, to_raylib_color(color)) // NOTE: Using `Pro` for rotating the sprite around its center
}

draw_multi_texture :: proc(multi_texture: Multi_Texture, #any_int index: i32, x, y: f32, color: Color = WHITE, rotation: f32 = 0.0, scale: f32 = 1.0) {
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

_draw_rectangle :: #force_inline proc "contextless" (x, y, w, h: f32, color: Color) {
	rl.DrawRectangleV(rl.Vector2{x,y}, rl.Vector2{w,h}, to_raylib_color(color))
}

draw_rectangle_by_center :: proc(center: mm.V2, w, h: f32, color: Color) {
	rl.DrawRectangleV(center-{w,h}/2, rl.Vector2{w,h}, to_raylib_color(color))
}

draw_rectangle_rotated :: proc(x, y, w, h: f32, color: Color, degrees: f32, pivot: Pivot) {
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
	rl.DrawRectanglePro(rect, origin, degrees, to_raylib_color(color))
}

draw_rectangle_by_center_rotated :: proc(cx, cy, w, h: f32, color: Color, degrees: f32, pivot: Pivot) {
	draw_rectangle_rotated(cx-w/2, cy-h/2, w, h, color, degrees, pivot)
}

_draw_line :: proc(start, end: mm.V2, thick: f32, color: Color) {
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

draw_circle_f32 :: proc(x, y, radius: f32, color: Color) {
	rl.DrawCircleV({x,y}, radius, to_raylib_color(color))
}
draw_circle_v2 :: proc(center: mm.V2, radius: f32, color: Color) {
	rl.DrawCircleV(center, radius, to_raylib_color(color))
}
draw_circle :: proc{draw_circle_f32,draw_circle_v2}

to_raylib_color :: #force_inline proc "contextless" (color: Color) -> rl.Color {
	return {
		cast(u8)( color.r*255+0.5 ),
		cast(u8)( color.g*255+0.5 ),
		cast(u8)( color.b*255+0.5 ),
		cast(u8)( color.a*255+0.5 ),
	}
}

Buffer_Target :: rl.RenderTexture2D
// NOTE(03/09/25): Maybe `#force_inline` these
_buffer_target_load :: proc(width, height: i32) -> Buffer_Target {
	return rl.LoadRenderTexture(width, height)
}
_buffer_target_unload :: proc(target: Buffer_Target) {
	rl.UnloadRenderTexture(target)
}

_buffer_target_begin :: proc(target: Buffer_Target, loc := #caller_location) {
	assert(rl.IsRenderTextureValid(target), loc=loc)
	assert(rl.IsRenderTextureReady(target), loc=loc)
	rl.BeginTextureMode(current_buffer_target_in_use)
}

_buffer_target_end :: proc "contextless" () {
	rl.EndTextureMode()
}


Shader :: rl.Shader
_shader_use_begin :: proc(shader: Shader) {
	rl.BeginShaderMode(shader)
}

_shader_use_end :: proc() {
	rl.EndShaderMode()
}

_shader_set_uniform :: proc(shader: Shader, name: string, datatype: Uniform_Datatype, data: rawptr, loc := #caller_location) {
	assert(datatype != .sampler2d, "Use `shader_set_uniform_texture` instead", loc=loc)
	uniform_loc := rl.GetShaderLocation(shader, fmt.ctprintf("%v", name))
	assert(uniform_loc != -1, loc=loc)
	rl.SetShaderValue(shader, uniform_loc, data, cast(rl.ShaderUniformDataType)datatype)
}

_shader_set_uniform_array :: proc(shader: Shader, name: string,
datatype: Uniform_Datatype, data: rawptr, count: i32, loc := #caller_location) {
	uniform_loc := rl.GetShaderLocation(shader, fmt.ctprintf("%v", name))
	assert(uniform_loc != -1, loc=loc)
	rl.SetShaderValueV(shader, uniform_loc, data, cast(rl.ShaderUniformDataType)datatype, count)
}

_shader_set_uniform_texture :: proc(shader: Shader, name: string, texture: Texture, loc := #caller_location) {
	uniform_loc := rl.GetShaderLocation(shader, fmt.ctprintf("%v", name))
	assert(uniform_loc != -1, loc=loc)
	rl.SetShaderValueTexture(shader, uniform_loc, texture)
}

texture_width :: proc(texture: Texture) -> i32 {
	return texture.width
}

texture_height :: proc(texture: Texture) -> i32 {
	return texture.height
}
