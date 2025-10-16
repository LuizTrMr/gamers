// A list tightly packed in memory, useful to process non ordered data.
// You can only delete elements by batch deleting a slice of them.
package batch

import "base:runtime"

Static :: struct($T: typeid, $N: int) {
	len: int,
	items: [N]T,
}

static_append :: proc(batch: ^Static($T, $N), item: T, loc := #caller_location) {
	assert(batch.len < N, loc=loc)
	batch.items[batch.len] = item
	batch.len += 1
}

static_alloc_item :: proc(batch: ^Static($T, $N), loc := #caller_location) -> (res:^T) {
	assert(batch.len < N, loc=loc)
	res  = &batch.items[batch.len]
	res^ = {}
	batch.len += 1
	return
}

static_clear :: proc(batch: ^Static($T, $N)) {
	batch.len = 0
}

static_slice :: proc(batch: ^Static($T, $N)) -> []T {
	return batch.items[:batch.len]
}

static_slice_inactives :: proc(batch: ^Static($T, $N)) -> []T {
	return batch.items[batch.len:]
}

@(private="file")
_static_unordered_remove :: proc(batch: ^Static($T, $N), index: int, loc := #caller_location) {
	assert(index < batch.len, loc=loc)
	batch.items[index], batch.items[batch.len-1] = batch.items[batch.len-1], batch.items[index]
	batch.len -= 1
}
static_unordered_remove :: proc(batch: ^Static($T, $N), to_remove: []int) {
	#reverse for index_to_remove in to_remove {
		_static_unordered_remove(batch, index_to_remove)
	}
}

Dynamic :: struct($T: typeid) {
	len: int,
	items: []T,
	allocator: runtime.Allocator,
}

dynamic_allocate :: proc(batch: ^Dynamic($T), #any_int n: int, allocator: runtime.Allocator, loc := #caller_location) -> (err: runtime.Allocator_Error) {
	batch.allocator  = allocator
	batch.items, err = make_slice([]T, n, batch.allocator, loc=loc)
	batch.len = 0
	return
}

dynamic_free :: proc(batch: ^Dynamic($T), loc := #caller_location) {
	err := delete(batch.items, batch.allocator, loc=loc)
	assert(err == nil, loc=loc)
}

dynamic_append :: proc(batch: ^Dynamic($T), item: T, loc := #caller_location) {
	assert(batch.len < len(batch.items), loc=loc)
	batch.items[batch.len] = item
	batch.len += 1
}

dynamic_alloc_item :: proc(batch: ^Dynamic($T), loc := #caller_location) -> (res:^T) {
	assert(batch.len < len(batch.items), loc=loc)
	res  = &batch.items[batch.len]
	res^ = {}
	batch.len += 1
	return
}

dynamic_clear :: proc(batch: ^Dynamic($T)) {
	batch.len = 0
}

dynamic_slice :: proc(batch: ^Dynamic($T)) -> []T {
	return batch.items[:batch.len]
}

dynamic_slice_inactives :: proc(batch: ^Dynamic($T)) -> []T {
	return batch.items[batch.len:]
}

@(private="file")
_dynamic_unordered_remove :: proc(batch: ^Dynamic($T), index: int, loc := #caller_location) {
	assert(index < batch.len, loc=loc)
	batch.items[index], batch.items[batch.len-1] = batch.items[batch.len-1], batch.items[index]
	batch.len -= 1
}
dynamic_unordered_remove :: proc(batch: ^Dynamic($T), to_remove: []int) {
	#reverse for index_to_remove in to_remove {
		_dynamic_unordered_remove(batch, index_to_remove)
	}
}

append           :: proc{static_append, dynamic_append, soa_static_append, soa_dynamic_append}
alloc_item       :: proc{static_alloc_item, dynamic_alloc_item, soa_static_alloc_item, soa_dynamic_alloc_item}
clear            :: proc{static_clear, dynamic_clear, soa_static_clear, soa_dynamic_clear}
slice            :: proc{static_slice, dynamic_slice, soa_static_slice, soa_dynamic_slice}
slice_inactives  :: proc{static_slice_inactives, dynamic_slice_inactives, soa_static_slice_inactives, soa_dynamic_slice_inactives}
unordered_remove :: proc{static_unordered_remove, dynamic_unordered_remove, soa_static_unordered_remove, soa_dynamic_unordered_remove}
allocate         :: proc{dynamic_allocate, soa_dynamic_allocate}
free             :: proc{dynamic_free    , soa_dynamic_free}
