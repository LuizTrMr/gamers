package platform_input

import "core:testing"
import "core:fmt"

import rl "vendor:raylib"

when PLATFORM == "RAYLIB" {

	is_key_pressed :: proc(key: Key) -> bool {
		return rl.IsKeyPressed(cast(rl.KeyboardKey) key)
	}

	is_key_down :: proc(key: Key) -> bool {
		return rl.IsKeyDown(cast(rl.KeyboardKey) key)
	}

	poll_keys :: proc() {
		rl.PollInputEvents()
	}

	// is_key_down :: proc(key: Key) -> bool {
	// 	return key_to_state[key].keydown
	// }

	// is_key_pressed :: proc(key: Key) -> bool {
	// 	return key_to_state[key].pressed
	// }

	// is_key_pressed :: proc(key: Key) -> bool {
	// 	return rl.IsKeyPressed(cast(rl.KeyboardKey) key)
	// }

}
