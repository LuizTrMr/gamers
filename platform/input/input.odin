package platform_input


DEBUG :: #config(DEBUG, true)

PLATFORM :: #config(PLATFORM, "RAYLIB")
#assert(PLATFORM == "RAYLIB" || PLATFORM == "CANVAS2D" || PLATFORM == "WEBGPU")

Key :: enum i32 { // TODO: Add all of the keyyyyyyyyyyyyyyyyys
	space = 32,

	zero  = 48,
	one   = 49,
	two   = 50,
	three = 51,
	four  = 52,
	five  = 53,
	six   = 54,
	seven = 55,
	eight = 56,
	nine  = 57,

	a = 65,
	d = 68,
	e = 69,

	j = 74,
	k = 75,

	p = 80,
	q = 81,
	r = 82,
	s = 83,
	u = 85,

	w = 87,
	z = 90,

	tab = 258,

	arrow_right = 262,
	arrow_left  = 263,
	arrow_down  = 264,
	arrow_up    = 265,
}

process_action :: proc(keys: []Key) -> (state: State) {
	for key in keys {
		if is_key_pressed(key) do state.is_pressed = true
		if is_key_down(key)    do state.is_down = true
	}
	return
}

State :: struct {
	is_down   : bool,
	is_pressed: bool,
}
key_to_state: #sparse [Key]State
