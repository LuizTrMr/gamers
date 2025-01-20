package platform_input

when PLATFORM == "CANVAS2D" || PLATFORM == "WEBGPU" {
	foreign import plat "web"
	foreign plat {
		// Input
		isKeyDown           :: proc "contextless" (key: i32) -> bool ---
		isKeyPressed        :: proc "contextless" (key: i32) -> bool ---
		isModDown           :: proc "contextless" (mod: i32) -> bool ---
		pollKeys            :: proc "contextless" ()                 ---
	}

	is_key_pressed :: proc(key: Key) -> bool {
		return isKeyPressed( i32(key) )
	}

	is_key_down :: proc(key: Key) -> bool {
		return isKeyDown( i32(key) )
	}

	poll_keys :: pollKeys
}
