// Pointer stable pool.
// We use generation keys to know if an item is the same.
// We store if an item is active and its generation key in a separate slice of `Key`s that encodes both.
// Free slots are found by linear search. This could be improved.
package libs_pool

import "base:runtime"

Key :: distinct u32 // 31st higher bit indicates if the slot is active or not

ACTIVE_BIT: u32: 0x10_00_00_00
@(private)
gen_key_from_key :: proc "contextless" (key: Key) -> u32 { return u32(key) & ~ACTIVE_BIT }
@(private)
is_active_from_key :: proc "contextless"(key: Key) -> bool { return u32(key) & ACTIVE_BIT != 0 }

Slot :: struct {
	handle : u32,
	gen_key: u32,
}

Static :: struct($T: typeid, $N: int) {
	items: [N]T,
	keys : [N]Key,
	len  : int,
}

static_reserve_slot :: proc(pool: ^Static($T, $N), loc := #caller_location) -> (res:Slot) {
	for key, handle in pool.keys {
		if !is_active_from_key(key) {
			gen_key := gen_key_from_key(pool.keys[handle])

			pool.keys[handle] = Key(gen_key | ACTIVE_BIT)
			pool.items[handle] = {} // Zero it

			res.gen_key = gen_key
			res.handle = auto_cast handle
			pool.len += 1
			return
		}
	}
	panic("Trying to alloc more than the budget", loc=loc)
}

static_append :: proc(pool: ^Static($T, $N), item: T, loc := #caller_location) -> (res:Slot) {
	slot := static_reserve_slot(pool, loc)
	pool.items[slot.handle] = item
	return slot
}

static_alloc_item :: proc(pool: ^Static($T, $N), loc := #caller_location) -> (^T, Slot) {
	slot := static_reserve_slot(pool, loc)
	return &pool.items[slot.handle], slot
}

static_remove :: proc(pool: ^Static($T, $N), #any_int handle: int, loc := #caller_location) {
	assert(is_active_from_key(pool.keys[handle]), loc=loc)
	current_key := pool.keys[handle]
	next_key: Key

	// Inactivate that slot in the pool
	next_key = current_key & Key(~ACTIVE_BIT)

	// Add to the gen_key
	gen_key := gen_key_from_key(next_key)
	next_key = Key(gen_key)+1

	// Commit changes
	pool.keys[handle] = next_key

	// We removed an item
	pool.len -= 1
}

static_remove_slot :: proc(pool: ^Static($T, $N), slot: Slot, loc := #caller_location) {
	assert( static_is_valid(pool^, slot) )
	static_remove(pool, slot.handle, loc)
}

static_batch_remove :: proc(pool: ^Static($T, $N), handles: []int, loc := #caller_location) {
	for handle in handles {
		static_remove(pool, handle, loc)
	}
}

static_clear :: proc(pool: ^Static($T, $N)) {
	pool.items = {}
	pool.keys  = {}
	pool.len   = 0
}

item :: proc(pool: ^Static($T, $N), slot: Slot, loc := #caller_location) -> T {
	return pool.items[slot.handle]
}

static_ptr :: proc(pool: ^Static($T, $N), slot: Slot, loc := #caller_location) -> ^T {
	return &pool.items[slot.handle]
}

static_safe_ptr :: proc(pool: ^Static($T, $N), slot: Slot, loc := #caller_location) -> ^T {
	assert(is_valid(pool^, slot), loc=loc)
	return &pool.items[slot.handle]
}

static_slot_from_handle :: proc(pool: Static($T, $N), #any_int handle: int) -> Slot {
	return {handle=auto_cast handle, gen_key=gen_key_from_key(pool.keys[handle])}
}

Iterator :: struct {
	index: int,
}

static_iterate :: proc(it: ^Iterator, pool: Static($T, $N)) -> (v:T, handle:int, more:bool) {
	for it.index < N && !is_active_from_key(pool.keys[it.index]) {
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
	for it.index < N && !is_active_from_key(pool.keys[it.index]) {
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
	items: []T,
	keys : []Key,
	len  : int,
	allocator: runtime.Allocator,
}

allocate :: proc(pool: ^Dynamic($T), n: int, allocator: runtime.Allocator, loc := #caller_location) {
	pool.allocator = allocator
	err: runtime.Allocator_Error
	pool.items, err = make_slice([]T  , n, pool.allocator)
	assert(err == nil, loc=loc)
	pool.keys, err = make_slice([]Key, n, pool.allocator)
	assert(err == nil, loc=loc)
}

dynamic_free :: proc(pool: ^Dynamic($T), loc := #caller_location) {
	err: runtime.Allocator_Error
	err = delete_slice(pool.items, pool.allocator)
	assert(err == nil, loc=loc)
	err = delete_slice(pool.keys, pool.allocator)
	assert(err == nil, loc=loc)
}

dynamic_reserve_slot :: proc(pool: ^Dynamic($T), loc := #caller_location) -> (res:Slot) {
	for key, handle in pool.keys {
		if !is_active_from_key(key) {
			gen_key := gen_key_from_key(pool.keys[handle])

			pool.keys[handle] = Key(gen_key | ACTIVE_BIT)
			pool.items[handle] = {} // Zero it

			res.gen_key = gen_key
			res.handle = auto_cast handle
			pool.len += 1
			return
		}
	}
	panic("Trying to alloc more than the budget", loc=loc)
}

dynamic_append :: proc(pool: ^Dynamic($T), item: T, loc := #caller_location) -> (res:Slot) {
	slot := dynamic_reserve_slot(pool, loc)
	pool.items[slot.handle] = item
	return slot
}

dynamic_remove :: proc(pool: ^Dynamic($T), #any_int handle: int, loc := #caller_location) {
	assert(is_active_from_key(pool.keys[handle]), loc=loc)
	current_key := pool.keys[handle]
	next_key: Key

	// Inactivate that slot in the pool
	next_key = current_key & Key(~ACTIVE_BIT)

	// Add to the gen_key
	gen_key := gen_key_from_key(next_key)
	next_key = Key(gen_key)+1

	// Commit changes
	pool.keys[handle] = next_key

	// We removed an item
	pool.len -= 1
}

dynamic_alloc_item :: proc(pool: ^Dynamic($T), loc := #caller_location) -> (^T, Slot) {
	slot := dynamic_reserve_slot(pool, loc)
	return &pool.items[slot.handle], slot
}

dynamic_batch_remove :: proc(pool: ^Dynamic($T), handles: []int, loc := #caller_location) {
	for handle in handles {
		dynamic_remove(pool, handle, loc)
	}
}

dynamic_clear :: proc(pool: ^Dynamic($T)) {
	pool.items  = {}
	pool.keys   = {}
	pool.len    = 0
}

dynamic_ptr :: proc(pool: ^Dynamic($T), slot: Slot, loc := #caller_location) -> ^T {
	return &pool.items[slot.handle]
}

dynamic_iterate :: proc(it: ^Iterator, pool: Dynamic($T)) -> (v:T, handle:int, more:bool) {
	for it.index < len(pool.items) && !is_active_from_key(pool.keys[it.index]) {
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
	for it.index < len(pool.items) && !is_active_from_key(pool.keys[it.index]) {
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

dynamic_init_from_slice :: proc(pool: ^Dynamic($T), slice: $E/[]T, allocator: runtime.Allocator, loc := #caller_location) {
	pool.allocator = allocator
	pool.items = slice
	pool.keys = make([]Key, len(slice), pool.allocator)
}

dynamic_delete_from_slice :: proc(pool: ^Dynamic($T), slice: $E/[]T, allocator: runtime.Allocator, loc := #caller_location) {
	delete(pool.keys, pool.allocator)
}

static_handle_is_active :: proc "contextless"(p: Static($T,$N), #any_int handle: int) -> bool { return is_active_from_key(p.keys[handle]) }
static_slot_is_active :: proc "contextless"(p: Static($T,$N), slot: Slot) -> bool { return is_active_from_key(p.keys[slot.handle]) }
dynamic_handle_is_active :: proc "contextless"(p: Dynamic($T), #any_int handle: int) -> bool { return is_active_from_key(p.keys[handle]) }
dynamic_slot_is_active :: proc "contextless"(p: Dynamic($T), slot: Slot) -> bool { return is_active_from_key(p.keys[slot.handle]) }
is_active :: proc{static_handle_is_active, static_slot_is_active, dynamic_handle_is_active, dynamic_slot_is_active}

static_is_valid :: proc "contextless" (p: Static($T,$N), slot: Slot) -> bool {
	same_gen_key := gen_key_from_key(p.keys[slot.handle]) == slot.gen_key
	is_active := is_active_from_key(p.keys[slot.handle])
	return same_gen_key && is_active
}

dynamic_is_valid :: proc "contextless" (p: Dynamic($T), slot: Slot) -> bool {
	return gen_key_from_key(p.keys[slot.handle]) == slot.gen_key && is_active_from_key(p.keys[slot.handle])
}

append         :: proc{static_append        , dynamic_append}
alloc_item     :: proc{static_alloc_item    , dynamic_alloc_item}
remove         :: proc{static_remove        , dynamic_remove, static_remove_slot}
batch_remove   :: proc{static_batch_remove  , dynamic_batch_remove}
clear          :: proc{static_clear         , dynamic_clear}
iterate        :: proc{static_iterate       , dynamic_iterate}
iterate_by_ptr :: proc{static_iterate_by_ptr, dynamic_iterate_by_ptr}
is_valid       :: proc{static_is_valid      , dynamic_is_valid} 
ptr            :: proc{static_ptr           , dynamic_ptr} 
safe_ptr       :: proc{static_safe_ptr} 
slot_from_handle :: proc{static_slot_from_handle}
