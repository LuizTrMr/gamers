#+build !js

package platform

import    "core:fmt"
import os "core:os/os2"

import rl "vendor:raylib"

_read_entire_file :: proc(name: string, allocator := context.allocator, loc := #caller_location) -> ([]byte, bool) {
	data, err := os.read_entire_file(name, allocator)
	return data, err == nil
}

_write_entire_file :: proc(name: string, data: []byte, truncate := true) -> (success: bool) {
	err := os.write_entire_file(name, data, truncate=truncate)
	return err == nil
}

_set_target_frames :: proc(fps: i32) {
	rl.SetTargetFPS(fps)
}

_get_frame_duration :: proc() -> f32 {
	return rl.GetFrameTime()
}

_open_simple :: proc(path: string) -> (^os.File, os.Error) {
	return os.open(path, os.O_RDWR | os.O_TRUNC | os.O_CREATE, 0o777)
}

_copy_file_from_to :: proc(from, to: string) {
	from_contents, err := os.read_entire_file(from, context.temp_allocator)
	assert(err == nil, fmt.tprintfln("from %v: %v", from, err))

	err2 := os.write_entire_file(to, from_contents)
	assert(err2 == nil, fmt.tprintfln("to %v: %v", to, err2))
}
