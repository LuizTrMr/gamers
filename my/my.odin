package gamers_my

import "core:mem"
import "core:mem/virtual"

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

wrap :: proc "contextless" (value, m: $T) -> T {
	value := (value % m + m) % m
	return value
}
