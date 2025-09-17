package pool

import "base:runtime"

SOA_Static :: struct($T: typeid, $N: int) {
	len: int,
	items: #soa[N]T,
}

soa_static_append :: proc(pool: ^SOA_Static($T, $N), item: T, loc := #caller_location) -> ^T {
	assert(pool.len < N, loc=loc)
	pool.items[pool.len] = item
	pool.len += 1
	return
}

soa_static_alloc_item :: proc(pool: ^SOA_Static($T, $N), loc := #caller_location) -> (res:^T) {
	assert(pool.len < N, loc=loc)
	res  = &pool.items[pool.len]
	res^ = {}
	pool.len += 1
	return
}

soa_static_unordered_remove :: proc(pool: ^SOA_Static($T, $N), index: int, loc := #caller_location) {
	assert(index < pool.len, loc=loc)
	pool.items[index], pool.items[pool.len-1] = pool.items[pool.len-1], pool.items[index]
	pool.len -= 1
}

soa_static_clear :: proc(pool: ^SOA_Static($T, $N)) {
	pool.len = 0
}

soa_static_slice :: proc(pool: ^SOA_Static($T, $N)) -> []T {
	return pool.items[:pool.len]
}

soa_static_slice_inactives :: proc(pool: ^SOA_Static($T, $N)) -> []T {
	return pool.items[pool.len:]
}

soa_static_batch_unordered_remove :: proc(pool: ^SOA_Static($T, $N), to_remove: []int) {
	#reverse for index_to_remove in to_remove {
		static_unordered_remove(pool, index_to_remove)
	}
}

SOA_Dynamic :: struct($T: typeid) {
	len: int,
	items: #soa[]T,
}

soa_dynamic_allocate :: proc(pool: ^SOA_Dynamic($T), n: int, allocator: runtime.Allocator) -> (err: runtime.Allocator_Error) {
	pool.items, err = make_soa_slice(#soa[]T, n, allocator)
	pool.len = 0
	return
}

soa_free :: proc(pool: ^SOA_Dynamic($T)) {
	free(pool.items)
}

soa_dynamic_append :: proc(pool: ^SOA_Dynamic($T), item: T, loc := #caller_location) {
	assert(pool.len < len(pool.items), loc=loc)
	pool.items[pool.len] = item
	pool.len += 1
}

soa_dynamic_alloc_item :: proc(pool: ^SOA_Dynamic($T), loc := #caller_location) -> (res:^T) {
	assert(pool.len < len(pool.items), loc=loc)
	res  = &pool.items[pool.len]
	res^ = {}
	pool.len += 1
	return
}

soa_dynamic_unordered_remove :: proc(pool: ^SOA_Dynamic($T), index: int, loc := #caller_location) {
	assert(index < pool.len, loc=loc)
	pool.items[index], pool.items[pool.len-1] = pool.items[pool.len-1], pool.items[index]
	pool.len -= 1
}

soa_dynamic_clear :: proc(pool: ^SOA_Dynamic($T)) {
	pool.len = 0
}

soa_dynamic_slice :: proc(pool: ^SOA_Dynamic($T)) -> #soa[]T {
	return pool.items[:pool.len]
}

soa_dynamic_slice_inactives :: proc(pool: ^SOA_Dynamic($T)) -> []T {
	return pool.items[pool.len:]
}

soa_dynamic_batch_unordered_remove :: proc(pool: ^SOA_Dynamic($T), to_remove: []int) {
	#reverse for index_to_remove in to_remove {
		soa_dynamic_unordered_remove(pool, index_to_remove)
	}
}
