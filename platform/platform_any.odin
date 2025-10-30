#+build !js

package platform

import "core:os"

import rl "vendor:raylib"

_read_entire_file :: proc(name: string, allocator := context.allocator, loc := #caller_location) -> (data: []byte, success: bool) {
	return os.read_entire_file(name, allocator, loc)
}

_write_entire_file :: proc(name: string, data: []byte, truncate := true) -> (success: bool) {
	return os.write_entire_file(name, data, truncate)
}

_set_target_frames :: proc(fps: i32) {
	rl.SetTargetFPS(fps)
}

_get_frame_duration :: proc() -> f32 {
	return rl.GetFrameTime()
}

_open_simple :: proc(path: string) -> (os.Handle, os.Error) {
	return os.open(path, os.O_RDWR | os.O_TRUNC | os.O_CREATE, 0o777)
}
