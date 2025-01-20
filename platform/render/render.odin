package platform_render

import "base:intrinsics"

import mm "../../my_math"

PLATFORM :: #config(PLATFORM, "RAYLIB")
#assert(PLATFORM == "RAYLIB" || PLATFORM == "WEBGPU" || PLATFORM == "CANVAS2D")

Color :: distinct mm.V4

BLANK      :: Color{0.0  , 0.0  , 0.0  , 0.0}
WHITE      :: Color{1.0  , 1.0  , 1.0  , 1.0}
BLACK      :: Color{0.0  , 0.0  , 0.0  , 1.0}
YELLOW     :: Color{1.0  , 1.0  , 0.0  , 1.0}
FULL_RED   :: Color{1.0  , 0.0  , 0.0  , 1.0}
FULL_GREEN :: Color{0.0  , 1.0  , 0.0  , 1.0}
GREEN_1    :: Color{0.0  , 1.0  , 0.768, 1.0}
FULL_BLUE  :: Color{0.0  , 0.0  , 1.0  , 1.0}
BLUE       :: Color{0.0  , 0.474, 0.945, 1.0}
RED        :: Color{0.901, 0.160, 0.215, 1.0}
EDITOR     :: Color{0.561, 0.788, 0.949, 1.0}

u32_to_color :: proc "contextless" (u: u32) -> (res: Color) {
	MASK :: 0xFF

	r := (u >> 24) & MASK
	g := (u >> 16) & MASK
	b := (u >>  8) & MASK
	a :=  u        & MASK

	res.r = f32(r) / 255
	res.g = f32(g) / 255
	res.b = f32(b) / 255
	res.a = f32(a) / 255

	return
}

mix :: proc "contextless" (a, b: Color, t: f32) -> Color {
	return a + (b-a)*t
}

Multi_Texture :: struct {
	texture: Texture `no_deserialize`,
	info   : struct {
		rows : i32,
		cols : i32,
		count: i32,
	},
}

multi_texture_cell_size :: #force_inline proc "contextless" (mt: Multi_Texture) -> mm.V2 {
	result: mm.V2
	result.x = f32(mt.texture.width  / mt.info.cols)
	result.y = f32(mt.texture.height / mt.info.rows)
	return result
}

texture_as_multi_texture :: proc(texture: Texture) -> Multi_Texture {
	mt: Multi_Texture
	mt.texture = texture
	mt.info = {1,1,1}
	return mt
}
