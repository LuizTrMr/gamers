package my_math

import "base:intrinsics"

import "core:slice"
import "core:fmt"
import "core:math/linalg"
import "core:math"
import "core:math/rand"

PI  :: math.PI
TAU :: math.TAU

to_degrees :: math.to_degrees_f32
to_radians :: math.to_radians_f32
mod        :: math.mod
sqrt       :: math.sqrt
floor      :: math.floor

roundf32_to_i32 :: proc "contextless" (v: f32) -> i32 {
	return cast(i32)(v + 0.5)
}

cbrt :: proc "contextless" (f: f32) -> f32 {
	return math.pow(f, 1/3)
}

norm :: proc "contextless" (start, end, value: f32) -> f32 {
	return (value - start) / (end - start)
}

norm_clamped :: proc "contextless" (start, end, value: f32) -> f32 {
	return clamp(norm(start, end, value), 0, 1)
}

//    /\
//   ( /   @ @    ()   @V2 stuff!
//    \  __| |__  /
//     -/   "   \-
//    /-|       |-\
//   / /-\     /-\ \
//    / /-`---'-\ \
//     /         \

V2            :: linalg.Vector2f32
V3            :: linalg.Vector3f32
V4            :: linalg.Vector4f32
normalize_v2  :: linalg.vector_normalize0
normalize     :: proc{norm, normalize_v2}
length        :: linalg.vector_length
length2       :: linalg.vector_length2
dot           :: linalg.vector_dot
distance      :: linalg.distance
array_cast    :: linalg.array_cast
angle_between :: linalg.angle_between

V2_ZERO  : V2 : 0
V2_UP    : V2 : {0,-1}
V2_RIGHT : V2 : {1, 0}
V2_DOWN  : V2 : {0, 1}
V2_LEFT  : V2 : {-1,0}

signed_angle_between :: proc "contextless" (a, b: V2) -> f32 { // Source: https://github.com/godotengine/godot/blob/4b36c0491edcecb1f800bc59ef2995921999c3c0/core/math/vector2.cpp#L92
	cross := a.x * b.y - a.y * b.x
	return math.atan2(cross, dot(a, b))
}

rotate_v2 :: proc "contextless" (v: V2, radians: f32) -> V2 {
	cos := math.cos(radians)
	sin := math.sin(radians)
	return {
		v.x * cos - v.y * sin,
		v.x * sin + v.y * cos,
	}
}

direction_from_angle :: proc "contextless" (radians: f32) -> V2 {
	return { math.cos(radians), math.sin(radians) }
}

is_near_f32 :: proc "contextless" (a, b: f32, distance: f32) -> bool {
	return a - distance <= b && b <= a + distance
}

is_near_v2 :: proc "contextless" (a, b: V2, radius: f32) -> bool {
	return length2(b-a) <= radius*radius
}

is_near :: proc{is_near_f32, is_near_v2}

sample_point_inside_rect :: proc(bound_a, bound_b: V2) -> (result: V2) {
	result.x = rand.float32_range(bound_a.x, bound_b.x)
	result.y = rand.float32_range(bound_a.y, bound_b.y)
	return
}

sample_point_inside_circle :: proc(center: V2, radius: f32) -> (result: V2) {
	bound_a := center - radius
	bound_b := center + radius
	for {
		result = sample_point_inside_rect(bound_a, bound_b)
		if length2(result - center) < radius * radius do return
	}
	return
}

sample_point_inside_circle_min_max :: proc(center: V2, min_radius, max_radius: f32) -> V2 {
	theta  := rand.float32() * 2 * PI
	r      := rand.float32_range(min_radius, max_radius)
	result := V2{ r * math.cos(theta), r * math.sin(theta) }
	return center + result
}

line_line_intersection_point :: proc(p1, p2, p3, p4: V2) -> (V2, bool) { // Source: https://paulbourke.net/geometry/pointlineplane/
	denom := (p4.y-p3.y)*(p2.x-p1.x) - (p4.x-p3.x)*(p2.y-p1.y)

	ua := ((p4.x-p3.x)*(p1.y-p3.y) - (p4.y-p3.y)*(p1.x-p3.x)) / denom
	ub := ((p2.x-p1.x)*(p1.y-p3.y) - (p2.y-p1.y)*(p1.x-p3.x)) / denom

	p := p1 + ua*(p2-p1)
	if ua >= 0 && ua <= 1 && ub >= 0 && ub <= 1 do return p, true

	return V2{}, false
}


// ───▄▄─▄████▄▐▄▄▄▌
// ──▐──████▀███▄█▄▌   @Splines!
// ▐─▌──█▀▌──▐▀▌▀█▀    Sources:
// ─▀───▌─▌──▐─▌           - https://www.youtube.com/watch?v=jvPPXbo87ds
// ─────█─█──▐▌█

/* NOTE(06/02/25): Not beign used anywhere in the game
quadratic_bezier :: proc "contextless" (p0, p1, p2: V2, t: f32) -> V2 {
	q0 := lerp(p0, p1, t)
	q1 := lerp(p1, p2, t)
	r  := lerp(q0, q1, t)
	return r
}

cubic_bezier :: proc "contextless" (p0, p1, p2, p3: V2, t: f32) -> V2 {
	q0 := lerp(p0, p1, t)
	q1 := lerp(p1, p2, t)
	q2 := lerp(p2, p3, t)

	r0 := lerp(q0, q1, t)
	r1 := lerp(q1, q2, t)

	s := lerp(r0, r1, t)
	return s
}
*/

Spline_Type :: enum {
	catmull,
	line,
	// B_Spline, // NOTE(04/02/25): I don't want to think about implementation if I am not gonna use it (which currently is the case)
}

Spline :: struct {
	type: Spline_Type,
	control_points: []V3, // NOTE(04/02/25): `z` value is used to store the segments length for uniform speeds

	u: f32,
	total_u: f32,

	// NOTE(06/02/25): Brother we are always gonna use constant speed
	f: f32, // NOTE(04/02/25): Same as `u`, but used for constant speed
	total_length: f32,
}

create_spline :: proc(points: []V3, type: Spline_Type) -> (spline: Spline) {
	spline.type           = type
	spline.control_points = points
	switch type {
	case .line:
		assert(len(points) >= 2, fmt.tprintfln("We have only %v points: %v", len(points), points))
		spline.total_u = cast(f32)len(points) - 1
		for i in 0..<len(points)-1 { // and I could calculate the lengths in advance when I build the final release of the game
			assert(points[i].z == 0)
			spline.control_points[i].z  = distance(spline.control_points[i].xy, spline.control_points[i+1].xy)
			spline.total_length        += spline.control_points[i].z
		}

	case .catmull:
		assert(len(points) >= 4, fmt.tprintfln("We have only %v points: %v", len(points), points))
		spline.total_u = cast(f32)len(points) - 3

		for i in 0..<len(points)-3 { // and I could calculate the lengths in advance when I build the final release of the game
			assert(points[i].z == 0)
			spline.control_points[i].z  = catmull_spline_calculate_segment_length(spline.control_points, i)
			spline.total_length        += spline.control_points[i].z
		}
	}
	return
}

@(require_results)
calculate :: proc(spline: Spline, delta: f32, speed: f32) -> (result: V2, ended: bool) {
	switch spline.type {
	case .catmull: result, ended = catmull_spline_calculate(spline, delta * speed)
	case .line   : result, ended = line_spline_calculate(spline, delta * speed)
	}
	return
}

@(require_results)
catmull_spline_calculate :: proc(spline: Spline, f: f32) -> (result: V2, ended: bool) {
	if f >= spline.total_length {
		ended = true
		return
	}
	offset := get_normalized_offset(spline.control_points, f)
	result = catmull_spline_get_point(spline.control_points, offset)
	return
}

@(require_results)
line_spline_calculate :: proc(spline: Spline, f: f32) -> (result: V2, ended: bool) {
	if f >= spline.total_length {
		ended = true
		return
	}
	offset := get_normalized_offset(spline.control_points, f)
	result = line_spline_get_point(spline.control_points, offset)
	return
}

increment :: proc(spline: ^Spline, delta: f32, speed: f32) -> (result: V2) {
	switch spline.type {
	case .catmull: result = catmull_spline_increment(spline, delta, speed)
	case .line   : result = line_spline_increment(spline, delta, speed)
	}
	return
}

line_spline_increment :: proc(spline: ^Spline, delta: f32, speed: f32) -> (result: V2) {
	offset := get_normalized_offset(spline.control_points, spline.f)
	result  = line_spline_get_point(spline.control_points, offset)
	spline.f += delta * speed
	return
}

catmull_spline_increment :: proc(spline: ^Spline, delta: f32, speed: f32) -> (result: V2) {
	result, _ = catmull_spline_calculate(spline^, spline.f)
	spline.f += delta * speed
	return
}
/* NOTE(06/02/25): Don't know what to do with these ones, I am not currently using them
*/

catmull_spline_calculate_segment_length :: proc(control_points: []V3, u_int: int) -> (length: f32) { // Source: https://www.youtube.com/watch?v=DzjtU4WLYNs
	step: f32: 0.005
	
	old, new: V2
	old = control_points[u_int].xy
	for t: f32 = 0.0; t < 1.0; t += step {
		new     = catmull_spline_get_point(control_points, f32(u_int)+t)
		length += distance(old, new)
		old     = new
	}
	return
}

@(require_results)
catmull_spline_get_point :: proc(control_points: []V3, u: f32) -> (result: V2) {
	assert(u >= 0)
	u_int := int(u)

	p1 := u_int + 1
	p0 := p1-1
	p2 := p1 + 1
	p3 := p2 + 1

	t  := u - f32(u_int)
	t2 := t*t
	t3 := t*t*t

	q0 := -t3 + 2*t2 - t
	q1 := 3*t3 - 5*t2 + 2
	q2 := -3*t3 + 4*t2 + t
	q3 := t3 - t2

	result = 0.5 * (control_points[p0].xy*q0 + control_points[p1].xy*q1 + control_points[p2].xy*q2 + control_points[p3].xy*q3)
	return
}

@(require_results)
line_spline_get_point :: proc(control_points: []V3, u: f32) -> (result: V2) {
	assert(u >= 0)

	u_int := int(u)
	t     := u - f32(u_int)
	result = lerp(control_points[u_int], control_points[u_int+1], t).xy
	return
}


@(require_results)
get_normalized_offset :: proc(control_points: []V3, offset: f32) -> (result: f32) {
	offset := offset
	i: int
	for offset > control_points[i].z {
		offset -= control_points[i].z
		i += 1
	}

	result = f32(i) + (offset / control_points[i].z)
	return
}


// b_spline :: proc(using spline: ^Spline, delta: f32) -> (result: V2) {
// 	return 0
	// u_int := int(u)

	// p0 := u_int
	// p1 := p0 + 1
	// p2 := p1 + 1
	// p3 := p2 + 1

	// t  := u - f32(u_int)
	// t2 := t*t
	// t3 := t*t*t

	// q0 := -t3 + 3*t2 - 3*t + 1
	// q1 := 3*t3 - 6*t2 + 4
	// q2 := -3*t3 + 3*t2 + 3*t + 1
	// q3 := t3

	// u += delta

	// result = 0.1666 * (control_points[p0]*q0 + control_points[p1]*q1 + control_points[p2]*q2 + control_points[p3]*q3)

	// return
// }

//         (__) 
//         (oo)  @Interpolation and @Easings!
//   /------\/   Sources:
//  / |    ||    	- https://easings.net/
// *  /\---/\       - https://github.com/godotengine/godot/blob/0f20e67d8de83c30b5dd79cb68d12d4cf613065d/scene/animation/easing_equations.h#L4

lerp_i32 :: proc "contextless" (a, b: i32, t: f32) -> i32 {
	return a + i32( f32(b - a) * t )
}

lerp_f32 :: proc "contextless" (a, b: f32, t: f32) -> f32 {
	return a + (b-a)*t
}

lerp_generic :: proc "contextless" (a, b: $T, t: f32) -> T { // Can be used by anything that contains f32s (e.g.: `V2` and `f32`)
	return a + (b-a)*t
}

lerp :: proc{lerp_i32, lerp_f32, lerp_generic}

cubic_in :: proc "contextless" (t: f32) -> f32 {
	return t * t * t
}

cubic_out :: proc "contextless" (t: f32) -> f32 {
	x := (1 - t)
	return 1.0 - x*x*x
}

cubic_in_out :: proc "contextless" (t: f32) -> f32 {
	return 4 * t * t * t if t < 0.5 else 1 - math.pow(-2 * t + 2, 3) / 2
}

cubic_out_in :: proc "contextless" (t: f32) -> f32 {
	return cubic_out(t) if t < 0.5 else cubic_in(t)
}

// @Parametric functions
// TODO: Add noise

// Source: https://en.wikipedia.org/wiki/Lemniscate_of_Bernoulli
bernoulli_lemniscate :: proc "contextless" (t: f32, a: f32, b: f32 = 1.0, θ: f32 = 0.0) -> (res: V2) {
	t := t * TAU
	t += PI/2 // NOTE: Offset so we don't teleport when t = 0

	res.x =     (a * math.cos(t))               / (1 + math.sin(t) * math.sin(t))
	res.y = b * (a * math.sin(t) * math.cos(t)) / (1 + math.sin(t) * math.sin(t))

	res = rotate_v2(res, θ)
	return
}

ellipse :: proc "contextless" (t: f32, a, b: f32, θ: f32 = 0.0) -> (res: V2) { // Source: https://en.wikipedia.org/wiki/Ellipse
	t := t * TAU
	res.x = a * math.cos(t)
	res.y = b * math.sin(t)
	if a >= b { res.x -= a } else { res.y -= b } // NOTE: Offset so we don't teleport when t = 0

	res = rotate_v2(res, θ)
	return
}

fish :: proc "contextless" (t: f32, a, b: f32, tail: f32 = 1.0, θ: f32 = 0.0) -> (res: V2) { // Source: https://www.reddit.com/r/mathmemes/comments/11y7gds/accidentally_found_the_equation_for_a_fish_while/
	t := t * TAU
	t += PI // NOTE: Offset so we don't teleport when t = 0

	res.x = (tail + math.cos(t)) * math.cos(t) * a
	res.y =         math.cos(t)  * math.sin(t) * b // NOTE: Removed the `+1` in y axis of the original equation because it only shifts the graph vertically

	res = rotate_v2(res, θ)
	return
}

// Geometry I guess
Bounds :: struct {
	start: V2,
	end  : V2,
}

is_point_inside_bounds :: proc "contextless" (p: V2, b: Bounds) -> bool {
	return p.x >= b.start.x && p.x <= b.end.x && p.y >= b.start.y && p.y <= b.end.y
}
