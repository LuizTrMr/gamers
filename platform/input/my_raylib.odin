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
	}

	get_mouse_position :: proc "contextless" () -> [2]f32 {
		return rl.GetMousePosition()
	}

}
