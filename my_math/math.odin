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
sign       :: math.sign_f32

roundf32_to_i32 :: proc "contextless" (v: f32) -> i32 {
	return cast(i32)(v + 0.5)
}

cbrt :: proc "contextless" (f: f32) -> f32 {
	return math.pow(f, 1/3)
}

normalize_f32 :: proc "contextless" (start, end, value: f32) -> f32 {
	return (value - start) / (end - start)
}
norm :: normalize_f32

norm_clamped :: proc "contextless" (start, end, value: f32) -> f32 {
	return clamp(norm(start, end, value), 0, 1)
}
normalize_clamped :: norm_clamped

//    /\
//   ( /   @ @    ()   @V2 stuff!
//    \  __| |__  /
//     -/   "   \-
//    /-|       |-\
//   / /-\     /-\ \
//    / /-`---'-\ \
//     /         \

V2            :: [2]f32
V3            :: [3]f32
V4            :: [4]f32
normalize_v2 :: #force_inline proc "contextless" (v: V2) -> V2 {
	return linalg.vector_normalize0(v)
}
normalize     :: proc{normalize_f32, normalize_v2}
length        :: linalg.vector_length
length2       :: linalg.vector_length2
dot           :: linalg.vector_dot
distance      :: linalg.distance
array_cast    :: linalg.array_cast
smallest_angle_between :: linalg.angle_between
orthogonal             :: linalg.orthogonal

@(deprecated="`angle_between` is deprecated, use `smallest_angle_between` instead")
angle_between :: linalg.angle_between

UP    : V2 : {0,-1}
RIGHT : V2 : {1, 0}
DOWN  : V2 : {0, 1}
LEFT  : V2 : {-1,0}

// TODO: Remove
V2_UP    :: UP
V2_RIGHT :: RIGHT
V2_DOWN  :: DOWN
V2_LEFT  :: LEFT

from_to :: #force_inline proc "contextless" (from, to: V2) -> V2 {
	return to-from
}

clamp_v2 :: proc "contextless" (v, minimum, maximum: V2) -> (res:V2) {
	res.x = clamp(v.x, minimum.x, maximum.x)
	res.y = clamp(v.y, minimum.y, maximum.y)
	return
}

signed_angle_between :: proc "contextless" (a, b: V2) -> f32 { // Source: https://github.com/godotengine/godot/blob/4b36c0491edcecb1f800bc59ef2995921999c3c0/core/math/vector2.cpp#L92
	cross := a.x * b.y - a.y * b.x
	return math.atan2(cross, dot(a, b))
}

@(require_results)
rotate_v2 :: proc "contextless" (v: V2, radians: f32) -> V2 { // Clockwise in raylib
	cos := math.cos(radians)
	sin := math.sin(radians)
	return {
		v.x * cos - v.y * sin,
		v.x * sin + v.y * cos,
	}
}
rotate :: rotate_v2

angle_from_direction :: proc "contextless" (dir: V2) -> (res:f32) {
	dir := normalize(dir)
	angle_between := smallest_angle_between(RIGHT, dir)
	if dir.y < 0 && dir.y != -0 {
		res = math.TAU - angle_between
	}
	else do res = angle_between
	return
}

direction_from_angle :: proc "contextless" (radians: f32) -> V2 {
	return { math.cos(radians), math.sin(radians) }
}

is_near_f32 :: proc "contextless" (fixed, to_test: f32, distance: f32) -> bool {
	return fixed - distance <= to_test && to_test <= fixed + distance
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
	theta  := rand.float32() * TAU
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

line_line_intersection :: proc(p1, p2, p3, p4: V2) -> bool {
	denom := (p4.y-p3.y)*(p2.x-p1.x) - (p4.x-p3.x)*(p2.y-p1.y)
	ua := ((p4.x-p3.x)*(p1.y-p3.y) - (p4.y-p3.y)*(p1.x-p3.x)) / denom
	ub := ((p2.x-p1.x)*(p1.y-p3.y) - (p2.y-p1.y)*(p1.x-p3.x)) / denom
	return ua >= 0 && ua <= 1 && ub >= 0 && ub <= 1
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
			assert(points[i+1].z == 0)
			spline.control_points[i+1].z  = catmull_spline_calculate_segment_length(spline.control_points, i)
			spline.total_length        += spline.control_points[i+1].z
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
spline_get_normalized_offset :: proc(spline: Spline, offset: f32) -> (res:f32) {
	switch spline.type {
	case .catmull: res = catmull_spline_get_normalized_offset(spline.control_points, offset)
	case .line   : res = line_spline_get_normalized_offset(spline.control_points, offset)
	}
	return
}

@(require_results)
catmull_spline_calculate :: proc(spline: Spline, f: f32) -> (result: V2, ended: bool) {
	if f >= spline.total_length {
		ended = true
		return
	}
	offset := catmull_spline_get_normalized_offset(spline.control_points, f)
	result = catmull_spline_get_point(spline.control_points, offset)
	return
}

@(require_results)
line_spline_calculate :: proc(spline: Spline, f: f32) -> (result: V2, ended: bool) {
	if f >= spline.total_length {
		ended = true
		return
	}

	offset := f
	i: int
	for offset > spline.control_points[i].z {
		offset -= spline.control_points[i].z
		i += 1
	}
	offset = f32(i) + (offset / spline.control_points[i].z)

	result = line_spline_get_point(spline.control_points, offset)
	return
}

// TODO: Use a more sofisticated approach to calculate the lengths, mainly in parts where there is a fast variation in gradient
catmull_spline_calculate_segment_length :: proc(control_points: []V3, u_int: int) -> (length: f32) { // Source: https://www.youtube.com/watch?v=DzjtU4WLYNs
	step: f32: 0.00001
	
	old, new: V2
	old = catmull_spline_get_point(control_points, f32(u_int))
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
catmull_spline_get_gradient :: proc(control_points: []V3, u: f32) -> (result: V2) {
	assert(u >= 0)
	u_int := int(u)

	p1 := u_int + 1
	p0 := p1-1
	p2 := p1 + 1
	p3 := p2 + 1

	t  := u - f32(u_int)
	t2 := t*t
	t3 := t*t*t

	q0 := -3*t2 + 4*t - 1
	q1 := 9*t2 - 10*t
	q2 := -9*t2 + 8*t + 1
	q3 := 3*t2 - 2*t

	result = 0.5 * (control_points[p0].xy*q0 + control_points[p1].xy*q1 + control_points[p2].xy*q2 + control_points[p3].xy*q3)
	return
}

spline_get_gradient :: proc(spline: Spline, u: f32) -> (result: V2) {
	switch spline.type {
	case .catmull: result = catmull_spline_get_gradient(spline.control_points, u)
	case .line   : result = line_spline_get_gradient(spline.control_points, u)
	}
	return
}

@(require_results)
line_spline_get_gradient :: proc(control_points: []V3, u: f32) -> (result: V2) {
	assert(u >= 0)
	u_int := int(u)
	result = from_to(control_points[u_int].xy, control_points[u_int+1].xy)
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
catmull_spline_get_normalized_offset :: proc(control_points: []V3, offset: f32) -> (result: f32) {
	offset := offset
	i: int
	for offset > control_points[i+1].z {
		offset -= control_points[i+1].z
		i += 1
	}

	result = f32(i) + (offset / control_points[i+1].z)
	return
}

@(require_results)
line_spline_get_normalized_offset :: proc(control_points: []V3, offset: f32) -> (result: f32) {
	offset := offset
	i: int
	for offset > control_points[i].z {
		offset -= control_points[i].z
		i += 1
	}

	result = f32(i) + (offset / control_points[i].z)
	return
}


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

lerp_v2 :: proc "contextless" (a, b: V2, t: f32) -> V2 {
	return a + (b-a)*t
}

lerp_generic :: proc "contextless" (a, b: $T, t: f32) -> T {
	return a + (b-a)*t
}

lerp :: proc{lerp_i32, lerp_f32, lerp_v2, lerp_generic}

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

// TODO: Test these
back_in :: proc "contextless" (t: f32) -> f32 {
	c1 :: 1.70158
	c3 :: c1 + 1
	return c3 * t * t * t - c1 * t * t
}

back_out :: proc "contextless" (t: f32) -> f32 {
	c1 :: 1.70158
	c3 :: c1 + 1

	return 1 + c3 * math.pow_f32(t - 1, 3) + c1 * math.pow_f32(t - 1, 2)
}

back_in_out :: proc "contextless" (t: f32) -> (res:f32) {
	c1 :: 1.70158
	c2 :: c1 * 1.525

	if t < 0.5 {
		res = (math.pow_f32(2 * t, 2) * ((c2 + 1) * 2 * t - c2)) / 2 
	}
	else {
		res = (math.pow_f32(2 * t - 2, 2) * ((c2 + 1) * (t * 2 - 2) + c2) + 2) / 2
	}
	return
}

back_out_in :: proc "contextless" (t: f32) -> f32 {
	return back_out(t) if t < 0.5 else back_in(t)
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

bounds_from_start_and_size :: proc(start, size: V2) -> (res:Bounds) {
	res.start = start
	res.end   = start+size
	return
}

bounds_size :: proc "contextless" (b: Bounds) -> V2 {
	return b.end-b.start
}

bounds_center :: proc "contextless" (b: Bounds) -> V2 {
	return b.start+bounds_size(b)/2
}

out_of_bounds :: proc "contextless" (object, bounds: Bounds) -> bool {
	return object.end.x   < bounds.start.x ||
	   	   object.start.x > bounds.end.x   ||
	   	   object.end.y   < bounds.start.x ||
	   	   object.start.y > bounds.end.y  
}

clockwise_points_from_bounds :: proc(bounds: Bounds) -> (p0, p1, p2, p3: V2) {
	size := bounds_size(bounds)
	p0 = bounds.start
	p1 = p0+{size.x,0}
	p2 = p1+{0,size.y}
	p3 = p2-{size.x,0}
	return
}

is_point_inside_rect :: proc "contextless" (p: V2, start: V2, size: V2) -> bool {
	return p.x >= start.x && p.x <= start.x+size.x && p.y >= start.y && p.y <= start.y+size.y
}

is_point_inside_bounds :: proc "contextless" (p: V2, b: Bounds) -> bool {
	return is_point_inside_rect(p, b.start, bounds_size(b))
}

is_point_inside_polygon :: proc(points: []V2, point: V2, raycast: V2) -> bool {
	if len(points) < 3 do return false
	raycast_start := point
	raycast_end   := point + raycast
	count: int
	for i in 0..<len(points)-1 {
		p0 := points[i]
		p1 := points[i+1]
		count += cast(int)line_line_intersection(p0, p1, raycast_start, raycast_end)
	}
	count += cast(int)line_line_intersection(points[len(points)-1], points[0], raycast_start, raycast_end)
	return count % 2 != 0
}

// @Random
random_direction :: proc() -> V2 {
	return direction_from_angle(rand.float32() * TAU)
}

random_int31_range :: proc(min, max: i32) -> i32 {
	return min + (rand.int31() % (max-min+1))
}
