#+build !js
package platform_input

import "core:fmt"

import rl "vendor:raylib"

when PLATFORM == "RAYLIB" {
	is_key_pressed :: proc(key: Key) -> bool {
		return rl.IsKeyPressed(cast(rl.KeyboardKey) key)
	}

	is_key_down :: proc(key: Key) -> bool {
		return rl.IsKeyDown(cast(rl.KeyboardKey) key)
	}

	get_mouse_position :: proc "contextless" () -> [2]f32 {
		return rl.GetMousePosition()
	}

	set_mouse_position :: proc "contextless" (pos: [2]f32) {
		rl.SetMousePosition(i32(pos.x+0.5),i32(pos.y+0.5))
	}

	is_mouse_button_pressed :: proc "contextless" (button: Mouse_Button) -> bool {
		return rl.IsMouseButtonPressed(cast(rl.MouseButton) button)
	}

	is_mouse_button_down :: proc "contextless" (button: Mouse_Button) -> bool {
		return rl.IsMouseButtonDown(cast(rl.MouseButton) button)
	}

	is_mouse_button_released :: proc "contextless" (button: Mouse_Button) -> bool {
		return rl.IsMouseButtonReleased(cast(rl.MouseButton) button)
	}

	// Stubs
	poll_keys :: proc() { }
}
