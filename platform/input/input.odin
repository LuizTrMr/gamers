package platform_input

PLATFORM :: #config(PLATFORM, "RAYLIB")
#assert(PLATFORM == "RAYLIB" || PLATFORM == "WEB")

Key :: enum i32 { // TODO: Add all of the keyyyyyyyyyyyyyyyyys (There are prolly some missing)
	none = 0,
	space = 32,
	
	apostrophe = 39,
    comma      = 44,
    minus      = 45,
    period     = 46,
    slash      = 47,

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

    semicolon = 59,
    equal     = 61,

	a = 65,
	b = 66,
	c = 67,
	d = 68,
	e = 69,
	f = 70,
	g = 71,
	h = 72,
	i = 73,
	j = 74,
	k = 75,
	l = 76,
	m = 77,
	n = 78,
	o = 79,
	p = 80,
	q = 81,
	r = 82,
	s = 83,
	t = 84,
	u = 85,
	v = 86,
	w = 87,
	x = 88,
	y = 89,
	z = 90,

	escape = 256,
    enter  = 257,
	tab    = 258,

    backspace = 259,
    insert    = 260,
    delete    = 261,

	arrow_right = 262,
	arrow_left  = 263,
	arrow_down  = 264,
	arrow_up    = 265,

	page_up      = 266,
    page_down    = 267,
    home         = 268,
    end          = 269,

    caps_lock    = 280,
    scroll_lock  = 281,
    num_lock     = 282,
    print_screen = 283,
    pause        = 284,

    F1  = 290,
    F2  = 291,
    F3  = 292,
    F4  = 293,
    F5  = 294,
    F6  = 295,
    F7  = 296,
    F8  = 297,
    F9  = 298,
    F10 = 299,
    F11 = 300,
    F12 = 301,

    left_shift    = 340,
    left_control  = 341,
    left_alt      = 342,
    left_super    = 343,
    right_shift   = 344,
    right_control = 345,
    right_alt     = 346,
    right_super   = 347,
}

Mouse_Button :: enum i32 {
	left,
	right,
}

process_key :: proc(key: Key) -> (state: State) {
	state.is_pressed = is_key_pressed(key)
	state.is_down    = is_key_down(key)
	return
}

process_keys :: proc(keys: []Key) -> (state: State) {
	for key in keys {
		if is_key_pressed(key) do state.is_pressed = true
		if is_key_down(key)    do state.is_down = true
	}
	return
}

process_mouse_button :: proc(button: Mouse_Button) -> (state: State) {
	state.is_pressed = is_mouse_button_pressed(button)
	state.is_down    = is_mouse_button_down(button)
	return
}

State :: struct {
	is_pressed: bool,
	is_down   : bool,
}
key_to_state: #sparse [Key]State


Key_Info :: struct {
	was_down: bool,
	half_transitions: i32,
}

input_state_from_key_info :: proc(info: Key_Info) -> (res:State) {
	res.is_down    = info.was_down
	res.is_pressed = (info.was_down  && info.half_transitions >= 1) ||
					 (!info.was_down && info.half_transitions >= 2)
	return
}
