#+build js
package platform_input

foreign import plat "web"
foreign plat {
	// input
	isKeyDown            :: proc "contextless" (key: i32) -> bool ---
	isKeyPressed         :: proc "contextless" (key: i32) -> bool ---
	isModDown            :: proc "contextless" (mod: i32) -> bool ---
	isMouseButtonDown    :: proc "contextless" (but: i32) -> bool ---
	isMouseButtonPressed :: proc "contextless" (but: i32) -> bool ---
	getMousePosX         :: proc "contextless" () -> f32 ---
	getMousePosY         :: proc "contextless" () -> f32 ---
	pollKeys             :: proc "contextless" ()                 ---
}

is_key_pressed :: proc(key: Key) -> bool {
	return isKeyPressed(cast(i32)key)
}

is_key_down :: proc(key: Key) -> bool {
	return isKeyDown(cast(i32)key)
}

is_mouse_button_pressed :: proc(button: Mouse_Button) -> bool {
	return isMouseButtonPressed(cast(i32)button)
}

is_mouse_button_down :: proc "contextless" (button: Mouse_Button) -> bool {
	return isMouseButtonDown(cast(i32)button)
}

get_mouse_position :: proc() -> [2]f32 {
	return {getMousePosX(), getMousePosY()}
}

set_mouse_position :: proc(pos: [2]f32) {
	// There is no way to implement this on web
}

poll_keys :: pollKeys
