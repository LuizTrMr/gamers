package tween

import    "core:fmt"
import    "core:log"
import mm "../my_math"
import    "../platform/render"

Handle  :: distinct i32

Supported_Pointers :: union {
	^f32,
	^mm.V2,
	^render.Color,
}
Supported_Values :: union {
	f32,
	mm.V2,
	render.Color,
}

Tween :: struct {
	state: State,
	v    : Supported_Pointers,
	start: Supported_Values,
	end  : Supported_Values,
	t: f32,
	total_duration: f32,
	interpolation: Interpolation_Type,

	to_chain: Handle,
}
POOL_SIZE :: 8
Manager :: struct {
	pool   : [POOL_SIZE]Tween,
}

State :: enum u8 {
	inactive_ready,
	inactive_waiting,

	active_ready,
}

insert_at :: proc(manager: ^Manager, v: Supported_Pointers, end: Supported_Values, seconds: f32,
				  interpolation: Interpolation_Type, at: Handle, state: State) {
	assert(manager.pool[at].state == .inactive_ready, fmt.tprintf("Trying to insert at slot %v, but its state is %v!", at, manager.pool[at].state))

	tween: Tween
	tween.state = state

	tween.v = v
	switch value in tween.v {
		case ^mm.V2       : tween.start = value^
		case ^f32         : tween.start = value^
		case ^render.Color: tween.start = value^
		case: log.fatalf("Unsupported value = %v", value)
	}
	tween.end    = end

	tween.t      = 0
	tween.total_duration = seconds
	tween.interpolation  = interpolation

	tween.to_chain = cast(Handle) -1

	manager.pool[at] = tween
}

append :: proc(manager: ^Manager, v: Supported_Pointers, end: Supported_Values, seconds: f32, interpolation: Interpolation_Type) -> Handle {
	for i in 0..<len(manager.pool) {
		if manager.pool[i].state == .inactive_ready {
			insert_at(manager, v, end, seconds, interpolation, cast(Handle) i, .active_ready)
			return cast(Handle) i
		}
	}
	log.fatalf("If we got here that means we ran out of tweens")
	return cast(Handle) -1
}

chain :: proc(manager: ^Manager, v: Supported_Pointers, end: Supported_Values, seconds: f32, interpolation: Interpolation_Type,
			  wait_for: Handle) -> Handle {
	for i in 0..<len(manager.pool) {
		if manager.pool[i].state == .inactive_ready {
			manager.pool[wait_for].to_chain = cast(Handle) i
			assert(manager.pool[wait_for].state == .active_ready, "If we need to wait for a tween that already ended then we are fucked")
			insert_at(manager, v, end, seconds, interpolation, cast(Handle) i, .inactive_waiting)
			return cast(Handle) i
		}
	}
	log.fatalf("If we got here that means we ran out of tweens")
	return cast(Handle) -1
}

update :: proc(manager: ^Manager, dt: f32) {
	for &tween in manager.pool {
		if tween.state == .inactive_ready || tween.state == .inactive_waiting do continue

		tween.t += dt

		t := tween.t/tween.total_duration
		switch tween.interpolation {
		case .linear: break

		case .cubic_in    : t = mm.cubic_in(t)
		case .cubic_out   : t = mm.cubic_out(t)
		case .cubic_in_out: t = mm.cubic_in_out(t)
		case .cubic_out_in: t = mm.cubic_out_in(t)

		}

		switch value in tween.v {
			case ^f32         : value^ = mm.lerp(tween.start.(f32)  , tween.end.(f32)  , t)
			case ^mm.V2       : value^ = mm.lerp(tween.start.(mm.V2), tween.end.(mm.V2), t)
			case ^render.Color: value^ = mm.lerp(tween.start.(render.Color), tween.end.(render.Color), t)
			case: log.fatalf("Unsupported value = %v", value)
		}

		if tween.t >= tween.total_duration {
			if tween.to_chain != -1 do manager.pool[tween.to_chain].state = .active_ready
			tween.state = .inactive_ready
		}
	}
}

Interpolation_Type :: enum {
	linear,

	cubic_in,
	cubic_out,
	cubic_in_out,
	cubic_out_in,
}
