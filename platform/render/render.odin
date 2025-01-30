package platform_render

import "base:intrinsics"
import "core:c/libc"

import mm "../../my_math"

PLATFORM :: #config(PLATFORM, "RAYLIB")
#assert(PLATFORM == "RAYLIB" || PLATFORM == "WEBGPU" || PLATFORM == "CANVAS2D")

Color :: mm.V4

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
PURPLE     :: Color{0.501, 0    , 0.501, 1.0}
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

mix_color :: proc "contextless" (a, b: [$N]f32, t: f32) -> [N]f32 where N >= 0 && N <= 4 {
	return a + (b-a)*t
}

mix_ok :: proc "contextless" (a, b: OkLab, t: f32) -> OkLab {
	a   := [3]f32{a.L, a.a, a.b}
	b   := [3]f32{b.L, b.a, b.b}
	res := a + (b-a)*t

	res.x = clamp(res.x, 0, 1)
	res.y = clamp(res.y, -0.4, 0.4)
	res.z = clamp(res.z, -0.4, 0.4)

	return {res[0], res[1], res[2]}
}

mix :: proc{mix_color, mix_ok}

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

// Color Picker: https://www.tawansunflower.com/colorpicker
OkLab :: struct {
	L, a, b: f32,
}

oklab_to_color :: proc "contextless" (color: OkLab) -> (res: Color) {
	l_ := color.L + 0.3963377774 * color.a + 0.2158037573 * color.b
    m_ := color.L - 0.1055613458 * color.a - 0.0638541728 * color.b
    s_ := color.L - 0.0894841775 * color.a - 1.2914855480 * color.b

    l := l_*l_*l_
    m := m_*m_*m_
    s := s_*s_*s_

	res.r =  4.0767416621 * l - 3.3077115913 * m + 0.2309699292 * s
	res.g = -1.2684380046 * l + 2.6097574011 * m - 0.3413193965 * s
	res.b = -0.0041960863 * l - 0.7034186147 * m + 1.7076147010 * s
	res.a = 1.0

    return
}

color_to_oklab :: proc "contextless" (c: Color) -> (res: OkLab) { 
	l := 0.4122214708 * c.r + 0.5363325363 * c.g + 0.0514459929 * c.b
	m := 0.2119034982 * c.r + 0.6806995451 * c.g + 0.1073969566 * c.b
	s := 0.0883024619 * c.r + 0.2817188376 * c.g + 0.6299787005 * c.b

	// TODO: Remove libc dependency?
    l_ := libc.cbrtf(l)
    m_ := libc.cbrtf(m)
    s_ := libc.cbrtf(s)

	res.L = 0.2104542553*l_ + 0.7936177850*m_ - 0.0040720468*s_
	res.a = 1.9779984951*l_ - 2.4285922050*m_ + 0.4505937099*s_
	res.b = 0.0259040371*l_ + 0.7827717662*m_ - 0.8086757660*s_
	
	return
}
