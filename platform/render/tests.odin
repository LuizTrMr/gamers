#+build !js
package platform_render

import "core:testing"

import rl "vendor:raylib"

@(test)
to_raylib_color_test :: proc(t: ^testing.T) {
	testing.expect(t, to_raylib_color(BLUE) == rl.BLUE, "my BLUE is not equal to rl.BLUE")
}
