package batch

import "base:runtime"

SOA_Static :: struct($T: typeid, $N: int) {
	len: int,
	items: #soa[N]T,
}

soa_static_append :: proc(batch: ^SOA_Static($T, $N), item: T, loc := #caller_location) -> ^T {
	assert(batch.len < N, loc=loc)
	batch.items[batch.len] = item
	batch.len += 1
	return
}

soa_static_alloc_item :: proc(batch: ^SOA_Static($T, $N), loc := #caller_location) -> (res:^T) {
	assert(batch.len < N, loc=loc)
	res  = &batch.items[batch.len]
	res^ = {}
	batch.len += 1
	return
}

soa_static_clear :: proc(batch: ^SOA_Static($T, $N)) {
	batch.len = 0
}

soa_static_slice :: proc(batch: ^SOA_Static($T, $N)) -> []T {
	return batch.items[:batch.len]
}

soa_static_slice_inactives :: proc(batch: ^SOA_Static($T, $N)) -> []T {
	return batch.items[batch.len:]
}

@(private="file")
_soa_static_unordered_remove :: proc(batch: ^SOA_Static($T, $N), index: int, loc := #caller_location) {
	assert(index < batch.len, loc=loc)
	batch.items[index], batch.items[batch.len-1] = batch.items[batch.len-1], batch.items[index]
	batch.len -= 1
}
soa_static_unordered_remove :: proc(batch: ^SOA_Static($T, $N), to_remove: []int) {
	#reverse for index_to_remove in to_remove {
		_soa_static_unordered_remove(batch, index_to_remove)
	}
}

SOA_Dynamic :: struct($T: typeid) {
	len: int,
	items: #soa[]T,
	allocator: runtime.Allocator,
}

soa_dynamic_allocate :: proc(batch: ^SOA_Dynamic($T), #any_int n: int, allocator: runtime.Allocator, loc := #caller_location) -> (err: runtime.Allocator_Error) {
	batch.allocator = allocator
	batch.items, err = make_soa_slice(#soa[]T, n, batch.allocator, loc=loc)
	batch.len = 0
	return
}

soa_dynamic_free :: proc(batch: ^SOA_Dynamic($T), loc := #caller_location) {
	err := delete_soa(batch.items, batch.allocator, loc=loc)
	assert(err == nil, loc=loc)
}

soa_dynamic_append :: proc(batch: ^SOA_Dynamic($T), item: T, loc := #caller_location) {
	assert(batch.len < len(batch.items), loc=loc)
	batch.items[batch.len] = item
	batch.len += 1
}

soa_dynamic_alloc_item :: proc(batch: ^SOA_Dynamic($T), loc := #caller_location) -> (res:^T) {
	assert(batch.len < len(batch.items), loc=loc)
	res  = &batch.items[batch.len]
	res^ = {}
	batch.len += 1
	return
}

soa_dynamic_clear :: proc(batch: ^SOA_Dynamic($T)) {
	batch.len = 0
}

soa_dynamic_slice :: proc(batch: ^SOA_Dynamic($T)) -> #soa[]T {
	return batch.items[:batch.len]
}

soa_dynamic_slice_inactives :: proc(batch: ^SOA_Dynamic($T)) -> []T {
	return batch.items[batch.len:]
}

@(private="file")
_soa_dynamic_unordered_remove :: proc(batch: ^SOA_Dynamic($T), index: int, loc := #caller_location) {
	assert(index < batch.len, loc=loc)
	batch.items[index], batch.items[batch.len-1] = batch.items[batch.len-1], batch.items[index]
	batch.len -= 1
}
soa_dynamic_unordered_remove :: proc(batch: ^SOA_Dynamic($T), to_remove: []int) {
	#reverse for index_to_remove in to_remove {
		_soa_dynamic_unordered_remove(batch, index_to_remove)
	}
}
