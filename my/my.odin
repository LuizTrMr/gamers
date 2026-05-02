package gamers_my

import "core:mem"
import "core:mem/virtual"
import "core:time"

Arena :: struct {
	using internal: mem.Arena,
	inited: bool,
	allocator: mem.Allocator,
}

arena_init :: proc(arena: ^Arena, data: []u8) {
	assert(!arena.inited)
	mem.arena_init(&arena.internal, data)
	arena.allocator = mem.arena_allocator(&arena.internal)
	arena.inited = true
}

DEFAULT_SIZE: uint: mem.Megabyte*32
arena_alloc :: proc(size := DEFAULT_SIZE) -> (arena: ^Arena) {
	data, err := virtual.reserve_and_commit(size)
	assert(err == nil)
	base := raw_data(data)
	arena = (^Arena)(base)
	data = data[size_of(Arena):]
	arena_init(arena, data)
	return
}

Period :: struct {
	curr, total: f32,
}
period_t :: proc "contextless" (period: Period) -> f32 { return period.curr / period.total }

/*
	Wraps `value` around [0,`m`-1]
*/
wrap :: proc "contextless" (value, m: $T) -> T {
	value := (value % m + m) % m
	return value
}

clamp_bot :: max
max_vector :: proc(vector0: [$N]f32, vector1: [N]f32) -> (res:[N]f32)
where N > 0 {
	for index in 0..<N {
		res[index] = max(vector0[index], vector1[index])
	}
	return res
}
clamp_bot_vector :: max_vector

clamp_top :: min
min_vector :: proc(vector0: [$N]f32, vector1: [N]f32) -> (res:[N]f32)
where N > 0 {
	for index in 0..<N {
		res[index] = min(vector0[index], vector1[index])
	}
	return res
}
clamp_top_vector :: min_vector

Timestamp :: time.Time
seconds_since_timestamp :: proc(timestamp: Timestamp) -> f32 {
	return cast(f32)time.duration_seconds(time.since(timestamp))
}

abs_vector :: proc(vector: [$N]f32) -> (res:[N]f32)
where N > 0 {
	for index in 0..<N {
		res[index] = abs(vector[index])
	}
	return
}

clamp_vector :: proc(value, min, max: [$N]f32) -> (res:[N]f32)
where N > 0 {
	for index in 0..<N {
		res[index] = clamp(value[index], min[index], max[index])
	}
	return
}
