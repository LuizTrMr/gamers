#+build js
package platform_render

import "core:fmt"

foreign import "web"
foreign web {
	// @setup
	initWindow :: proc "contextless" (width, height: i32) ---
	enableMouseCursor :: proc "contextless" () ---
	disableMouseCursor :: proc "contextless" () ---

	// @render
	clearBackground :: proc "contextless" (r, g, b, a: u8) ---
	drawRectangle   :: proc "contextless" (x, y, w, h: f32, r,g,b,a: u8) ---
	drawRectangleRotated :: proc "contextless" (x, y, w, h, degrees: f32, r,g,b,a: u8) ---
	drawCircle      :: proc "contextless" (cx, cy: f32, radius: f32, r,g,b,a: u8) ---
	drawLine        :: proc "contextless" (startx, starty, endx, endy: f32, thick: f32, r, g, b, a: u8) ---
	drawTexture     :: proc "contextless" (#any_int id: i32, x, y: f32) ---
	drawTextureFull :: proc "contextless" (#any_int id: i32, src_x, src_y, src_w, src_h, dst_x, dst_y, dst_w, dst_h: f32) ---
	drawMultiTexture :: proc "contextless" (#any_int id: i32, index: i32, rows, cols: i32, x, y: f32) ---
	drawText         :: proc "contextless" (font: []byte, address: [^]byte, len: i32, x, y: f32, font_size: f32, r,g,b,a: u8) ---

	getTextWidth  :: proc "contextless" (font: []byte, address: [^]byte, len: i32, font_size: f32) -> f32 ---
	getTextHeight :: proc "contextless" (font: []byte, address: [^]byte, len: i32, font_size: f32) -> f32 ---

	textureGenerate  :: proc "contextless" ()             -> u32 ---
	textureLoad      :: proc "contextless" (path: []byte) -> u32 ---
	textureLoaded    :: proc "contextless" (id: u32)      -> bool ---
	textureGetWidth  :: proc "contextless" (id: u32)      -> i32 ---
	textureGetHeight :: proc "contextless" (id: u32)      -> i32 ---

	offscreenCanvasCreateContext  :: proc "contextless" (width: i32, height: i32) -> u32 ---
    getLatestTexture              :: proc "contextless" () -> u32 ---
	setCurrentContext             :: proc "contextless" (id: u32) ---
	blitContextToImage            :: proc "contextless" (u32, u32) ---

	camera2dBegin :: proc "contextless" (x, y: f32) ---
	camera2dEnd   :: proc "contextless" () ---
}

get_text_size :: proc(font: Font, text: cstring, font_size: f32) -> [2]f32 {
	width  := getTextWidth (transmute([]byte)font, transmute([^]byte)text, cast(i32)len(text), font_size)
	height := getTextHeight(transmute([]byte)font, transmute([^]byte)text, cast(i32)len(text), font_size)
	return {width, height}
}

draw_texture_rectangle :: proc(texture: Texture, x, y: f32, rectangle: Rectangle, color: Color = WHITE) {
	drawTextureFull(texture.id,
					rectangle.x, rectangle.y, rectangle.width, rectangle.height,
					x, y, f32(texture.width), f32(texture.height))
}

Font :: string
font_default :: proc() -> Font {
	return "Arial"
}

set_mouse_cursor :: proc(opt: Option) {
	switch opt {
	case .enable : enableMouseCursor()
	case .disable: disableMouseCursor()
	}
}

Texture :: struct {
	id: u32,
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
	drawRectangleRotated(x, y, w, h, degrees, to_platform_color(color))
}

load_texture :: proc(path: string) -> (res: Texture) {
	res.id     = textureLoad(transmute([]byte)path)
	res.width  = textureGetWidth(res.id)
    res.height = textureGetHeight(res.id)
	return
}

load_texture_from_memory :: proc(memory: []byte) -> Texture {
	return {}
}

draw_texture_f32 :: proc(texture: Texture, x, y: f32, color: Color = WHITE, rotation: f32 = 0.0, scale: f32 = 1.0) {
	// TODO: color, rotation, scale?
	drawTexture(texture.id, x, y)
}
draw_texture_v2 :: proc(texture: Texture, pos: [2]f32, color: Color = WHITE, rotation: f32 = 0.0, scale: f32 = 1.0) {
	draw_texture_f32(texture, pos.x, pos.y, color, rotation, scale)
}
draw_texture :: proc{draw_texture_f32, draw_texture_v2}

draw_multi_texture :: proc(multi_texture: Multi_Texture, #any_int index: i32, x, y: f32, color: Color = WHITE, rotation: f32 = 0.0, scale: f32 = 1.0) {
	drawMultiTexture(multi_texture.texture.id, index, multi_texture.info.rows, multi_texture.info.cols, x, y)
}

draw_text :: proc(font: Font, text: cstring, x, y: f32, font_size: i32, color: Color) {
	drawText(transmute([]byte)font, transmute([^]byte)text, cast(i32)len(text), x, y, cast(f32) font_size, to_platform_color(color))
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

draw_circle_f32 :: proc(x, y, radius: f32, color: Color) {
	drawCircle(x, y, radius, to_platform_color(color))
}
draw_circle_v2 :: proc(center: [2]f32, radius: f32, color: Color) {
	drawCircle(center.x, center.y, radius, to_platform_color(color))
}
draw_circle :: proc{draw_circle_f32,draw_circle_v2}


_camera2d_begin :: proc(camera: Camera2D) {
	camera2dBegin(camera.position.x, camera.position.y)
}

_camera2d_end :: proc() {
	camera2dEnd()
}

Buffer_Target :: struct {
	id: u32,
	width, height: i32,
	texture: Texture,
}

buffer_target_load :: proc(width, height: i32) -> (res:Buffer_Target) {
	res.width  = width
	res.height = height
	res.id = offscreenCanvasCreateContext(width, height)
	res.texture.id = getLatestTexture()
	res.texture.width  = width
	res.texture.height = height
	return
}

_buffer_target_begin :: proc "contextless" (target: Buffer_Target) {
	setCurrentContext(target.id)
}

_buffer_target_end :: proc () {
	blitContextToImage(current_buffer_target_in_use.id, current_buffer_target_in_use.texture.id)
	setCurrentContext(0)
}

Shader :: u32
_shader_use_begin :: proc(shader: Shader) { assert(false) }
_shader_use_end   :: proc() { assert(false) }
_shader_set_uniform :: proc(shader: Shader, uniform_name: string, datatype: Uniform_Datatype, data: rawptr) { assert(false) }
_shader_set_uniform_array :: proc(shader: Shader, uniform_name: string, datatype: Uniform_Datatype, data: rawptr, count: i32) {
	assert(false)
}

texture_width :: proc(texture: Texture) -> i32 {
	return textureGetWidth(texture.id)
}

texture_height :: proc(texture: Texture) -> i32 {
	return textureGetHeight(texture.id)
}

close_window  :: proc() {/* No implementation */}
begin_drawing :: proc() {/* No implementation */}
swap_buffers  :: proc() {/* No implementation */}
