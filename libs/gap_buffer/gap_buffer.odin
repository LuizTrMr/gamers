package libs_gap_buffer

import "core:mem"
import "core:strings"

// @gap_buffer
Gap_Buffer :: struct {
	buf: []u8,
	gap_start: int,
	gap_size : int,
}
gap_buffer_init :: proc(buffer: ^Gap_Buffer, size: uint, allocator: mem.Allocator) {
	buffer.buf       = make([]u8, size, allocator)
	buffer.gap_start = 0
	buffer.gap_size  = auto_cast size
}
gap_buffer_move_cursor_left :: proc(buffer: ^Gap_Buffer) {
	assert(buffer.gap_start > 0)
	byte := buffer.buf[buffer.gap_start-1]
	buffer.gap_start -= 1
	end := buffer.gap_start+buffer.gap_size
	buffer.buf[end] = byte
}
gap_buffer_move_cursor_right :: proc(buffer: ^Gap_Buffer) {
	byte := buffer.buf[buffer.gap_start+buffer.gap_size]
	buffer.buf[buffer.gap_start] = byte
	buffer.gap_start += 1
}
gap_buffer_user_backspace :: proc(buffer: ^Gap_Buffer) {
	// a[ ]bc NOTE: `gap_size` > 0
	// [ ]abc
	// [  ]bc

	// a[b]c NOTE: `gap_size` == 0
	// [a]bc
	// [ ]bc
	gap_buffer_move_cursor_left(buffer)
	end := buffer.gap_start+buffer.gap_size
	buffer.buf[end] = 0
	buffer.gap_size += 1
}
gap_buffer_write_byte :: proc(buffer: ^Gap_Buffer, byte: u8) -> bool {
	if buffer.gap_size == 0 do return false

	buffer.buf[buffer.gap_start] = byte
	buffer.gap_start += 1
	buffer.gap_size  -= 1
	return true
}
gap_buffer_user_can_move_right :: #force_inline proc "contextless" (buffer: Gap_Buffer) -> bool {
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
gap_buffer_user_can_move_left :: #force_inline proc "contextless" (buffer: Gap_Buffer) -> bool {
	return buffer.gap_start > 0
}
gap_buffer_string_size :: proc(buffer: Gap_Buffer) -> int {
	return len(buffer.buf)-buffer.gap_size
}
gap_buffer_to_string :: proc(buffer: Gap_Buffer, allocator: mem.Allocator) -> string {
	end := buffer.gap_start+buffer.gap_size
	return strings.concatenate({string(buffer.buf[:buffer.gap_start]), string(buffer.buf[end:])}, allocator)
}
gap_buffer_clear :: proc(buffer: ^Gap_Buffer) {
	buffer.gap_start = 0
	buffer.gap_size  = len(buffer.buf)
	buffer.buf = {}
}
gap_buffer_string_until_cursor :: proc(buffer: Gap_Buffer) -> string { return string(buffer.buf[:buffer.gap_start]) }
gap_buffer_write_string :: proc(buffer: ^Gap_Buffer, text: string) -> bool {
	if buffer.gap_size == 0 do return false
	n := copy(buffer.buf[buffer.gap_start:], text)
	assert(n == len(text))
	buffer.gap_start += n
	buffer.gap_size  -= n
	return true
}
