package pool

import "base:runtime"

Static :: struct($T: typeid, $N: int) {
	len: int,
	items: [N]T,
}

static_append :: proc(pool: ^Static($T, $N), item: T, loc := #caller_location) {
	assert(pool.len < N, loc=loc)
	pool.items[pool.len] = item
	pool.len += 1
}

static_alloc_item :: proc(pool: ^Static($T, $N), loc := #caller_location) -> (res:^T) {
	assert(pool.len < N, loc=loc)
	res  = &pool.items[pool.len]
	res^ = {}
	pool.len += 1
	return
}

static_unordered_remove :: proc(pool: ^Static($T, $N), index: int, loc := #caller_location) {
	assert(index < pool.len, loc=loc)
	pool.items[index], pool.items[pool.len-1] = pool.items[pool.len-1], pool.items[index]
	pool.len -= 1
}

static_clear :: proc(pool: ^Static($T, $N)) {
	pool.len = 0
}

static_slice :: proc(pool: ^Static($T, $N)) -> []T {
	return pool.items[:pool.len]
}

static_slice_inactives :: proc(pool: ^Static($T, $N)) -> []T {
	return pool.items[pool.len:]
}

static_batch_unordered_remove :: proc(pool: ^Static($T, $N), to_remove: []int) {
	#reverse for index_to_remove in to_remove {
		static_unordered_remove(pool, index_to_remove)
	}
}

Dynamic :: struct($T: typeid) {
	len: int,
	items: []T,
}

dynamic_allocate :: proc(pool: ^Dynamic($T), n: int, allocator: runtime.Allocator) -> (err: runtime.Allocator_Error) {
	pool.items, err = make_slice([]T, n, allocator)
	pool.len = 0
	return
}

free :: proc(pool: ^Dynamic($T)) {
	free(pool.items)
}

dynamic_append :: proc(pool: ^Dynamic($T), item: T, loc := #caller_location) {
	assert(pool.len < len(pool.items), loc=loc)
	pool.items[pool.len] = item
	pool.len += 1
}

dynamic_alloc_item :: proc(pool: ^Dynamic($T), loc := #caller_location) -> (res:^T) {
	assert(pool.len < len(pool.items), loc=loc)
	res  = &pool.items[pool.len]
	res^ = {}
	pool.len += 1
	return
}

dynamic_unordered_remove :: proc(pool: ^Dynamic($T), index: int, loc := #caller_location) {
	assert(index < pool.len, loc=loc)
	pool.items[index], pool.items[pool.len-1] = pool.items[pool.len-1], pool.items[index]
	pool.len -= 1
}

dynamic_clear :: proc(pool: ^Dynamic($T)) {
	pool.len = 0
}

dynamic_slice :: proc(pool: ^Dynamic($T)) -> []T {
	return pool.items[:pool.len]
}

dynamic_slice_inactives :: proc(pool: ^Dynamic($T)) -> []T {
	return pool.items[pool.len:]
}

dynamic_batch_unordered_remove :: proc(pool: ^Dynamic($T), to_remove: []int) {
	#reverse for index_to_remove in to_remove {
		dynamic_unordered_remove(pool, index_to_remove)
	}
}

append           :: proc{static_append, dynamic_append, soa_static_append, soa_dynamic_append}
alloc_item       :: proc{static_alloc_item, dynamic_alloc_item, soa_static_alloc_item, soa_dynamic_alloc_item}
unordered_remove :: proc{static_unordered_remove, dynamic_unordered_remove, soa_static_unordered_remove, soa_dynamic_unordered_remove}
clear            :: proc{static_clear, dynamic_clear, soa_static_clear, soa_dynamic_clear}
slice            :: proc{static_slice, dynamic_slice, soa_static_slice, soa_dynamic_slice}
slice_inactives  :: proc{static_slice_inactives, dynamic_slice_inactives, soa_static_slice_inactives, soa_dynamic_slice_inactives}
batch_unordered_remove  :: proc{static_batch_unordered_remove, dynamic_batch_unordered_remove, soa_static_batch_unordered_remove, soa_dynamic_batch_unordered_remove}

allocate :: proc{dynamic_allocate, soa_dynamic_allocate}
