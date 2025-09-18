package games_libs_double_buffer

Double_Buffer :: struct($T: typeid) {
	buffers: [2]T,
	current: ^T,
	next   : ^T,
}

init :: proc(double_buffer: ^Double_Buffer($T), first, second: T) {
	double_buffer.buffers[0] = first
	double_buffer.buffers[1] = second
	double_buffer.current = &double_buffer.buffers[0]
	double_buffer.next    = &double_buffer.buffers[1]
}

swap :: proc(double_buffer: ^Double_Buffer($T)) {
	double_buffer.current, double_buffer.next = double_buffer.next, double_buffer.current
}

get_read :: proc(double_buffer: Double_Buffer($T)) -> T {
	return double_buffer.current^
}

get_write :: proc(double_buffer: Double_Buffer($T)) -> ^T {
	return double_buffer.next
}
