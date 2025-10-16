package tween

import    "core:fmt"
import    "core:log"
import    "core:math/linalg"
import mm "../my_math"
import    "../libs/batch"

Handle  :: distinct i32

Supported_Pointers :: union {
	^f32,
	^[2]f32,
	^[4]f32,
	^quaternion128,
}
Supported_Values :: union {
	f32,
	[2]f32,
	[4]f32,
	quaternion128,
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

// TODO: Reimplement this system using pointer stable pools.
POOL_SIZE :: 10
Manager :: struct {
	tweens: batch.Static(Tween, POOL_SIZE),
}

State :: enum u8 {
	inactive_ready,
	inactive_waiting,
	active_ready,
}

insert_at :: proc(manager: ^Manager, v: Supported_Pointers, end: Supported_Values, seconds: f32,
				  interpolation: Interpolation_Type, at: Handle, state: State) {
	assert(manager.tweens.items[at].state == .inactive_ready, fmt.tprintf("Trying to insert at slot %v, but its state is %v!", at, manager.tweens.items[at].state))

	tween: Tween
	tween.state = state

	tween.v = v
	switch value in tween.v {
		case ^f32          : tween.start = value^
		case ^[2]f32       : tween.start = value^
		case ^[4]f32       : tween.start = value^
		case ^quaternion128: tween.start = value^
		case: log.fatalf("Unsupported value = %v", value)
	}
	tween.end    = end

	tween.t      = 0
	tween.total_duration = seconds
	tween.interpolation  = interpolation

	tween.to_chain = cast(Handle) -1

	manager.tweens.items[at] = tween
}

append :: proc(manager: ^Manager, v: Supported_Pointers, end: Supported_Values, seconds: f32, interpolation: Interpolation_Type) -> Handle {
	tween := batch.alloc_item(&manager.tweens)
	handle := cast(Handle)manager.tweens.len-1

	tween.v = v
	switch value in tween.v {
		case ^f32          : tween.start = value^
		case ^[2]f32       : tween.start = value^
		case ^[4]f32       : tween.start = value^
		case ^quaternion128: tween.start = value^
		case: log.fatalf("Unsupported value = %v", value)
	}
	tween.end    = end

	tween.t      = 0
	tween.total_duration = seconds
	tween.interpolation  = interpolation

	tween.to_chain = cast(Handle) -1

	// batch.append(&manager.tweens, 
	// for i in 0..<len(manager.tweens) {
	// 	if manager.tweens[i].state == .inactive_ready {
	// 		insert_at(manager, v, end, seconds, interpolation, cast(Handle) i, .active_ready)
	// 		return cast(Handle) i
	// 	}
	// }
	// log.fatalf("If we got here that means we ran out of tweens")
	return handle
}

chain :: proc(manager: ^Manager, v: Supported_Pointers, end: Supported_Values,
			  seconds: f32, interpolation: Interpolation_Type, wait_for: Handle
) -> Handle {
	for i in 0..<manager.tweens.len {
		if manager.tweens.items[i].state == .inactive_ready {
			manager.tweens.items[wait_for].to_chain = cast(Handle) i
			assert(manager.tweens.items[wait_for].state == .active_ready, "If we need to wait for a tween that already ended then we are fucked")
			insert_at(manager, v, end, seconds, interpolation, cast(Handle) i, .inactive_waiting)
			return cast(Handle) i
		}
	}
	log.fatalf("If we got here that means we ran out of tweens")
	return cast(Handle) -1
}

update :: proc(manager: ^Manager, dt: f32) {
	for &tween, handle in batch.slice(&manager.tweens) {
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
		t = clamp(t, 0, 1)

		switch value in tween.v {
			case ^f32          : value^ = mm.lerp(tween.start.(f32)   , tween.end.(f32)  , t)
			case ^[2]f32       : value^ = mm.lerp(tween.start.([2]f32), tween.end.([2]f32), t)
			case ^[4]f32       : value^ = mm.lerp(tween.start.([4]f32), tween.end.([4]f32), t)
			case ^quaternion128: value^ = linalg.quaternion_slerp_f32(tween.start.(quaternion128), tween.end.(quaternion128), t)
			case: log.fatalf("Unsupported value = %v", value)
		}

		if tween.t >= tween.total_duration {
			if tween.to_chain != -1 do manager.tweens.items[tween.to_chain].state = .active_ready
			tween.state = .inactive_ready
		}
	}
}

is_tween_done :: proc(manager: Manager, handle: Handle) -> bool {
	tween := manager.tweens.items[handle]
	return tween.t >= tween.total_duration
}

Interpolation_Type :: enum {
	linear,

	cubic_in,
	cubic_out,
	cubic_in_out,
	cubic_out_in,
}
