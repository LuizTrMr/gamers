// Pointer stable pool.
// Free slots are found by linear search. This could be improved.
// We store if a slot is allocated with a separate slice of active elements (as a slice of bools). This could be improved.
package pool

import "base:runtime"

Static :: struct($T: typeid, $N: int) {
	items  : [N]T,
	actives: [N]bool,
}

static_append :: proc(pool: ^Static($T, $N), item: T, loc := #caller_location) -> int {
	for active, handle in pool.actives {
		if !active {
			pool.actives[handle] = !pool.actives[handle]
			pool.items[handle] = item
			return handle
		}
	}
	assert(false, "Trying to alloc more than the budget", loc=loc)
	return -1
}

static_alloc_item :: proc(pool: ^Static($T, $N), loc := #caller_location) -> ^T {
	zero: T
	handle := static_append(pool, zero, loc)
	return &pool.items[handle]
}

static_remove :: proc(pool: ^Static($T, $N), #any_int handle: int, loc := #caller_location) {
	assert(pool.actives[handle], loc=loc)
	pool.actives[handle] = !pool.actives[handle]
}

static_batch_remove :: proc(pool: ^Static($T, $N), handles: []int, loc := #caller_location) {
	for handle in handles {
		remove(pool, handle)
	}
}

static_clear :: proc(pool: ^Static($T, $N)) {
	pool.items   = {}
	pool.actives = {}
}

Iterator :: struct {
	index: int,
}

static_iterate :: proc(it: ^Iterator, pool: Static($T, $N)) -> (v:T, handle:int, more:bool) {
	for it.index < N && !pool.actives[it.index] {
		it.index += 1
	}
	if it.index >= N {
		it.index = 0 // automatically restart
		return
	}
	v = pool.items[it.index]
	handle = it.index
	more = true
	it.index += 1
	return
}

static_iterate_by_ptr :: proc(it: ^Iterator, pool: ^Static($T, $N)) -> (v:^T, handle:int, more:bool) {
	for it.index < N && !pool.actives[it.index] {
		it.index += 1
	}
	if it.index == N {
		it.index = 0 // automatically restart
		return
	}
	v = &pool.items[it.index]
	handle = it.index
	more = true
	it.index += 1
	return
}

Dynamic :: struct($T: typeid) {
	items  : []T,
	actives: []bool,
	allocator: runtime.Allocator,
}

allocate :: proc(pool: ^Dynamic($T), n: int, allocator: runtime.Allocator, loc := #caller_location) {
	pool.allocator = allocator
	err: runtime.Allocator_Error
	pool.items, err = make_slice([]T  , n, pool.allocator)
	assert(err == nil, loc=loc)
	pool.actives, err = make_slice([]bool, n, pool.allocator)
	assert(err == nil, loc=loc)
}

dynamic_free :: proc(pool: ^Dynamic($T), loc := #caller_location) {
	err: runtime.Allocator_Error
	err = delete_slice(pool.items  , pool.allocator)
	assert(err == nil, loc=loc)
	err = delete_slice(pool.actives, pool.allocator)
	assert(err == nil, loc=loc)
}

dynamic_append :: proc(pool: ^Dynamic($T), item: T, loc := #caller_location) -> int {
	for active, handle in pool.actives {
		if !active {
			pool.actives[handle] = !pool.actives[handle]
			pool.items[handle] = item
			return handle
		}
	}
	assert(false, "Trying to alloc more than the budget", loc=loc)
	return -1
}

dynamic_alloc_item :: proc(pool: ^Dynamic($T), loc := #caller_location) -> ^T {
	zero: T
	handle := dynamic_append(pool, zero, loc)
	return &pool.items[handle]
}

dynamic_remove :: proc(pool: ^Dynamic($T), #any_int handle: int, loc := #caller_location) {
	assert(pool.actives[handle], loc=loc)
	pool.actives[handle] = !pool.actives[handle]
}

dynamic_batch_remove :: proc(pool: ^Dynamic($T), handles: []int, loc := #caller_location) {
	for handle in handles {
		remove(pool, handle)
	}
}

dynamic_clear :: proc(pool: ^Dynamic($T)) {
	pool.items   = {}
	pool.actives = {}
}

dynamic_iterate :: proc(it: ^Iterator, pool: Dynamic($T)) -> (v:T, handle:int, more:bool) {
	for it.index < len(pool.items) && !pool.actives[it.index] {
		it.index += 1
	}
	if it.index >= len(pool.items) {
		it.index = 0 // automatically restart
		return
	}
	v = pool.items[it.index]
	handle = it.index
	more = true
	it.index += 1
	return
}

dynamic_iterate_by_ptr :: proc(it: ^Iterator, pool: ^Dynamic($T)) -> (v:^T, handle:int, more:bool) {
	for it.index < len(pool.items) && !pool.actives[it.index] {
		it.index += 1
	}
	if it.index == len(pool.items) {
		it.index = 0 // automatically restart
		return
	}
	v = &pool.items[it.index]
	handle = it.index
	more = true
	it.index += 1
	return
}

append         :: proc{static_append        , dynamic_append}
alloc_item     :: proc{static_alloc_item    , dynamic_alloc_item}
remove         :: proc{static_remove        , dynamic_remove}
batch_remove   :: proc{static_batch_remove  , dynamic_batch_remove}
clear          :: proc{static_clear         , dynamic_clear}
iterate        :: proc{static_iterate       , dynamic_iterate}
iterate_by_ptr :: proc{static_iterate_by_ptr, dynamic_iterate_by_ptr}
