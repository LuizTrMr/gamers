package libs_pool

import "core:testing"

@(test)
zero_slot_is_invalid :: proc(t: ^testing.T) {
	pool: Static(int, 5)
	slot: Slot
    testing.expect(t, !is_valid(pool, slot), "A zero slot must be invalid")
}
