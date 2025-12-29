package platform

import os "core:os"
import os2 "core:os/os2"

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

open :: proc(path: string) -> (^os2.File, os2.Error) {
	return _open_simple(path)
}

create_package :: proc(name: string, identifier: string, version_first, version_second, version_third: int) {
	_create_package(name, identifier, version_first, version_second, version_third)
}

copy_file_from_to :: proc(from, to: string) {
	_copy_file_from_to(from, to)
}

create_or_open :: proc(path: string) -> (os.Handle, os.Error) {
	return _create_or_open(path)
}
