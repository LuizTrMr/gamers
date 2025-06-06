package platform_render

import "base:intrinsics"
import "core:math"
import "core:fmt"

import mm "../../my_math"

Color :: mm.V4

BLANK      :: Color{0.0  , 0.0  , 0.0  , 0.0}
WHITE      :: Color{1.0  , 1.0  , 1.0  , 1.0}
BLACK      :: Color{0.0  , 0.0  , 0.0  , 1.0}
YELLOW     :: Color{1.0  , 1.0  , 0.0  , 1.0}
GOLDEN     :: Color{1.0  , 0.843, 0.0  , 1.0}
FULL_RED   :: Color{1.0  , 0.0  , 0.0  , 1.0}
FULL_GREEN :: Color{0.0  , 1.0  , 0.0  , 1.0}
GREEN_1    :: Color{0.0  , 1.0  , 0.768, 1.0}
FULL_BLUE  :: Color{0.0  , 0.0  , 1.0  , 1.0}
BLUE       :: Color{0.0  , 0.474, 0.945, 1.0}
RED        :: Color{0.901, 0.160, 0.215, 1.0}
PURPLE     :: Color{0.501, 0    , 0.501, 1.0}
ORANGE     :: Color{1.0  , 0.498, 0.313, 1.0}
EDITOR     :: Color{0.561, 0.788, 0.949, 1.0}

// Color Harmonies
complementary_from :: proc(color: Color) -> (res: Color) {
	res.rgb = 1 - color.rgb
	res.a = color.a
	return
}

rgb_to_color :: proc(rgb: [3]f32) -> (res: Color) {
	for i in 0..<len(rgb) {
		assert(0 <= rgb[i]  , fmt.tprintfln("%v value = %v", i, rgb[i]))
		assert(rgb[i] <= 255, fmt.tprintfln("%v value = %v", i, rgb[i]))
	}

	res.rgb = rgb/255
	res.a   = 1
	return
}

color_to_u8s :: proc(color: Color) -> (res: [3]u8) {
	res[0] = cast(u8)math.round(color[0]*255)
	res[1] = cast(u8)math.round(color[1]*255)
	res[2] = cast(u8)math.round(color[2]*255)
	return
}

u8s_to_color :: proc(color: [3]u8, a: f32 = 1) -> (res: Color) {
	res[0] = f32(color[0])/255
	res[1] = f32(color[1])/255
	res[2] = f32(color[2])/255
	res.a  = a
	return
}

color_to_rgb :: proc(color: Color) -> (res: [3]f32) {
	for i in 0..<len(color)-1 {
		assert(0 <= color[i], fmt.tprintfln("%v value = %v", i, color[i]))
		assert(color[i] <= 1, fmt.tprintfln("%v value = %v", i, color[i]))
	}

	res.r = math.round(color.r*255)
	res.g = math.round(color.g*255)
	res.b = math.round(color.b*255)
	return
}

u32_to_color :: proc "c" (u: u32, a: f32 = 1.0) -> (res: Color) { // NOTE(16/02/25): Alpha defined separately for ease of use
	MASK :: 0xFF

	r := (u >> 16) & MASK
	g := (u >>  8) & MASK
	b :=  u        & MASK

	res.r = f32(r) / 255
	res.g = f32(g) / 255
	res.b = f32(b) / 255
	res.a = 1.0

	return
}
color_from_u32 :: u32_to_color

mix_color :: proc "c" (a, b: [$N]f32, t: f32) -> [N]f32 where N >= 0 && N <= 4 {
	return a + (b-a)*t
}

mix_ok :: proc "c" (a, b: OkLab, t: f32) -> OkLab {
	a   := [3]f32{a.L, a.a, a.b}
	b   := [3]f32{b.L, b.a, b.b}
	res := a + (b-a)*t

	// TODO: Is this really necessary?
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
	},
}

multi_texture_cell_size :: #force_inline proc "contextless" (mt: Multi_Texture) -> (res: mm.V2) {
	res.x = f32(mt.texture.width  / mt.info.cols)
	res.y = f32(mt.texture.height / mt.info.rows)
	return
}

multi_texture_count :: #force_inline proc(mt: Multi_Texture, loc := #caller_location) -> i32 {
	assert(mt.info.rows > 0, loc=loc)
	assert(mt.info.cols > 0, loc=loc)
	return mt.info.rows*mt.info.cols
}

texture_as_multi_texture :: proc(texture: Texture) -> Multi_Texture {
	mt: Multi_Texture
	mt.texture = texture
	mt.info = {1,1}
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

    l_ := mm.cbrt(l)
    m_ := mm.cbrt(m)
    s_ := mm.cbrt(s)

	res.L = 0.2104542553*l_ + 0.7936177850*m_ - 0.0040720468*s_
	res.a = 1.9779984951*l_ - 2.4285922050*m_ + 0.4505937099*s_
	res.b = 0.0259040371*l_ + 0.7827717662*m_ - 0.8086757660*s_
	
	return
}

HSV :: distinct [3]f32

// Source: https://github.com/bottosson/bottosson.github.io/blob/f6f08b7fde9436be1f20f66cebbc739d660898fd/misc/colorpicker/colorconversion.js#L73
rgb_to_hsv :: proc(r, g, b: f32) -> HSV {
	r := r/255
    g := g/255
    b := b/255

    max := max(r, g, b)
	min := min(r, g, b)
    h, s: f32
    v := max

    d := max - min
    s = max == 0 ? 0 : d / max

    if max == min {
        h = 0 // achromatic
    } 
    else {
        switch(max){
            case r: 
                h = (g - b) / d + (g < b ? 6 : 0)
            case g: 
                h = (b - r) / d + 2
            case b: 
                h = (r - g) / d + 4
        }
        h /= 6
    }

    return {h, s, v}
}

hsv_to_rgb :: proc(h, s, v: f32) -> [3]f32 {
    r, g, b: f32

    i := math.floor(h * 6)
    f := h * 6 - i
    p := v * (1 - s)
    q := v * (1 - f * s)
    t := v * (1 - (1 - f) * s)

    switch(i32(i) % 6){
        case 0:
            r = v
            g = t 
            b = p
        case 1:
            r = q
            g = v 
            b = p
        case 2:
            r = p
            g = v 
            b = t
        case 3:
            r = p
            g = q 
            b = v
        case 4:
            r = t
            g = p 
            b = v
        case 5:
            r = v
            g = p 
            b = q
		case:
			fmt.println("oh shit")
			assert(false)
    }

    return {r * 255, g * 255, b * 255}
}

hsv_to_color :: proc(col: HSV) -> Color {
	h := col[0] / 360
	s := col[1] / 100
	v := col[2] / 100

	rgb := hsv_to_rgb(h,s,v)
	return rgb_to_color(rgb)
}

color_to_hsv :: proc(col: Color) -> (res: HSV) {
	rgb := color_to_rgb(col)
	hsv := rgb_to_hsv(expand_values(rgb))

	res[0] = math.round(hsv[0] * 360)
	res[1] = math.round(hsv[1] * 100)
	res[2] = math.round(hsv[2] * 100)
	return
}

Pivot :: enum {
	top_left,
	top_center,
	top_right,

	mid_left,
	center,
	mid_right,

	bottom_left,
	bottom_center,
	bottom_right,
}
