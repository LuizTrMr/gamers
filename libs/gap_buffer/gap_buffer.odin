package libs_gap_buffer

import "core:mem"
import "core:strings"

// @gap_buffer
Gap_Buffer :: struct {
	buf: []u8,
	gap_start: int,
	gap_size : int,
}
init :: proc(buffer: ^Gap_Buffer, size: uint, allocator: mem.Allocator) {
	buffer.buf       = make([]u8, size, allocator)
	buffer.gap_start = 0
	buffer.gap_size  = auto_cast size
}
move_cursor_left :: proc(buffer: ^Gap_Buffer, zero := false) {
	assert(buffer.gap_start > 0)
	byte := buffer.buf[buffer.gap_start-1]
	buffer.gap_start -= 1
	end := buffer.gap_start+buffer.gap_size
	buffer.buf[end] = byte
	if zero {
		buffer.buf[buffer.gap_start] = 0
	}
}
move_cursor_left_by :: proc(buffer: ^Gap_Buffer, #any_int n: int, zero := false) {
	assert(buffer.gap_start-n >= 0)
	end := buffer.gap_start
	buffer.gap_start -= n
	copied := copy_slice(buffer.buf[buffer.gap_start+buffer.gap_size:], buffer.buf[buffer.gap_start:end])
	assert(copied == n)
	if zero && buffer.gap_start < end {
		mem.zero(&buffer.buf[buffer.gap_start:end][0], n)
	}
}
move_cursor_right :: proc(buffer: ^Gap_Buffer, zero := false) {
	byte := buffer.buf[buffer.gap_start+buffer.gap_size]
	buffer.buf[buffer.gap_start] = byte
	buffer.gap_start += 1
	if zero {
		buffer.buf[buffer.gap_start+buffer.gap_size-1] = 0
	}
}
move_cursor_right_by :: proc(buffer: ^Gap_Buffer, #any_int n: int, zero := false) {
	start := buffer.gap_start
	buffer.gap_start += n
	copied := copy_slice(buffer.buf[start:buffer.gap_start],
		buffer.buf[start+buffer.gap_size:start+buffer.gap_size+n])
	assert(copied == n)
	if zero && buffer.gap_start+buffer.gap_size-n > 0 {
		mem.zero(&buffer.buf[buffer.gap_start+buffer.gap_size-n:][0], n)
	}
}

user_can_backspace :: user_can_move_left
user_backspace :: proc(buffer: ^Gap_Buffer, zero := false) {
	// a[ ]bc NOTE: `gap_size` > 0
	// [ ]abc
	// [  ]bc

	// a[b]c NOTE: `gap_size` == 0
	// [a]bc
	// [ ]bc
	move_cursor_left(buffer, zero)
	end := buffer.gap_start+buffer.gap_size
	buffer.buf[end] = 0
	buffer.gap_size += 1
}
write_byte :: proc(buffer: ^Gap_Buffer, byte: u8) -> bool {
	if buffer.gap_size == 0 do return false

	buffer.buf[buffer.gap_start] = byte
	buffer.gap_start += 1
	buffer.gap_size  -= 1
	return true
}
user_can_move_right :: #force_inline proc "contextless" (buffer: Gap_Buffer) -> bool {
	end := buffer.gap_start+buffer.gap_size
	left := len(buffer.buf)-end
	can_move: bool
	for index in end..<end+left {
		if buffer.buf[index] != 0 { // there is content, so user can move
			can_move = true
			break
		}
	}
	return can_move
}
user_can_move_left :: #force_inline proc "contextless" (buffer: Gap_Buffer) -> bool {
	return buffer.gap_start > 0
}
gap_buffer_string_size :: proc(buffer: Gap_Buffer) -> int {
	return len(buffer.buf)-buffer.gap_size
}
to_string :: proc(buffer: Gap_Buffer, allocator: mem.Allocator) -> string {
	end := buffer.gap_start+buffer.gap_size
	return strings.concatenate({string(buffer.buf[:buffer.gap_start]), string(buffer.buf[end:])}, allocator)
}
gap_buffer_clear :: proc(buffer: ^Gap_Buffer) {
	buffer.gap_start = 0
	buffer.gap_size  = len(buffer.buf)
	buffer.buf = {}
}
gap_buffer_string_until_cursor :: proc(buffer: Gap_Buffer) -> string { return string(buffer.buf[:buffer.gap_start]) }
write_string :: proc(buffer: ^Gap_Buffer, text: string) -> bool {
	if buffer.gap_size == 0 do return false
	n := copy(buffer.buf[buffer.gap_start:], text)
	assert(n == len(text))
	buffer.gap_start += n
	buffer.gap_size  -= n
	return true
}

set_cursor_position :: proc(buffer: ^Gap_Buffer, #any_int x: int, zero := false) {
	current_cursor := buffer.gap_start
	by := abs(x-current_cursor)
	if x > current_cursor {
		by = min(by, len(buffer.buf)-buffer.gap_size-buffer.gap_start)
		move_cursor_right_by(buffer, by, zero)
	}
	else if x < current_cursor {
		by = min(by, buffer.gap_start)
		move_cursor_left_by(buffer, by, zero)
	}
}
zero :: proc(buffer: ^Gap_Buffer, #any_int start, end: int) {
	mem.zero_slice(buffer.buf[start:end])
}
index_of_content_end :: proc(buffer: Gap_Buffer, #any_int start_at: int = 0) -> int {
	index := start_at
	for index < len(buffer.buf) && buffer.buf[index] != 0 do index += 1
	return index
}
