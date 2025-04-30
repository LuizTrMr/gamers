package gamers_libs

Handle :: int

Pool_Node :: struct($T: typeid) {
	next_available: int,
	value         : T,
}

Pool :: struct($T: typeid, $N: int) {
	items: [N]Pool_Node(T),
	first_available: int,
	inited: bool,
}

init :: proc(pool: ^Pool($T, $N)) {
	assert(!pool.inited)

	for &item, i in pool.items[:len(pool.items)-1] {
		item.next_available = i+1
	}
	pool.items[len(pool.items)-1].next_available = -1
}

@require_results
alloc :: proc(pool: ^Pool($T, $N)) -> (res: Handle) {
	index := pool.first_available
	assert(index != -1, "Pool ran out of items")
	node  := pool.items[index]

	pool.items[index].value = {} // Zero it

	pool.first_available = node.next_available
	return index
}

@require_results
grab :: proc(pool: ^Pool($T, $N), handle: Handle) -> ^T {
	assert(handle < len(pool.items))
	return &pool.items[handle].value
}

free :: proc(pool: ^Pool($T, $N), handle: Handle) {
	assert(handle < len(pool.items))
	pool.items[handle].next_available = pool.first_available
	pool.first_available = handle
}

free_all :: proc(pool: ^Pool($T, $N)) {
	pool.first_available = 0
	for &item, i in pool.items[:len(pool.items)-1] {
		item.next_available = i+1
	}
	pool.items[len(pool.items)-1].next_available = -1
}
