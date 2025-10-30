package platform

import "core:os"

PLATFORM :: #config(PLATFORM, "RAYLIB")
#assert(PLATFORM == "RAYLIB" || PLATFORM == "WEB")

@(require_results)
read_entire_file :: proc(name: string, allocator := context.allocator, loc := #caller_location) -> (data: []byte, success: bool) {
	return _read_entire_file(name, allocator, loc)
}

write_entire_file :: proc(name: string, data: []byte, truncate := true) -> (success: bool) {
	return _write_entire_file(name, data, truncate)
}

set_target_frames :: proc(fps: i32) {
	_set_target_frames(fps)
}

get_frame_duration :: proc() -> f32 {
	return _get_frame_duration()
}

open :: proc(path: string) -> (os.Handle, os.Error) {
	return _open_simple(path)
}
