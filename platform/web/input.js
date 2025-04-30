class State {
	constructor() {
		this.is_down = false;
		this.is_pressed = false;
	}
}

const code_to_value = Object.freeze({
    "Space": 32,

	"KeyA": 65,
	"KeyD": 68,
	"KeyE": 69,

	"KeyQ": 81,
	"KeyR": 82,
	"KeyS": 83,

	"KeyW": 87,
	"KeyZ": 90,

	"ArrowRight": 262,
	"ArrowLeft" : 263,
	"ArrowDown" : 264,
	"ArrowUp"   : 265,
});

const Mods = Object.freeze({
	"Alt"    : 1,
	"Shift"  : 2,
	"Control": 4,
	"Meta"   : 8,
});

let Input = {
	mods: 0,

	value_to_state: { // I have to instance a fucking object for each entry here, javascript I guess 🤡
		32: new State(),

		65: new State(),
		68: new State(),
		69: new State(),

		81: new State(),
		82: new State(),
		83: new State(),

		87: new State(),
		90: new State(),

		262: new State(),
		263: new State(),
		264: new State(),
		265: new State(),
	},

	mouse: {
		left : new State(),
		right: new State(),
	},
	mouseX: 0,
	mouseY: 0,
};

document.addEventListener("is_down", (event) => {
	if (event.key in Mods) {
		Input.mods |= Mods[event.key];
		return;
	}

	const value = code_to_value[event.code];
	console.assert(value !== undefined, `Keydown code: ${event.code} not supported`);
	if (value === undefined) return;
	
	Input.value_to_state[value].is_pressed = !Input.value_to_state[value].is_down;
	Input.value_to_state[value].is_down = true;
});

document.addEventListener("keyup", (event) => {
	if (event.key in Mods) {
		Input.mods &= ~Mods[event.key];
		return;
	}

	const value = code_to_value[event.code];
	console.assert(value !== undefined, `Keyup code: ${event.code} not supported`);
	if (value === undefined) return;

	console.assert(Input.value_to_state[value].is_down === true);
	Input.value_to_state[value].is_down = false;
});

document.addEventListener('mousedown', function(e) {
	if (e.button === 0) {
		Input.mouse.left.is_pressed = !Input.mouse.left.is_down;
		Input.mouse.left.is_down = true;
	}
	else if (e.button === 2) {
		Input.mouse.right.is_pressed = !Input.mouse.right.is_down;
		Input.mouse.right.is_down = true;
	}

});

document.addEventListener('mouseup', function(e) {
	if (e.button === 0) {
		Input.mouse.left.is_down = false;
	}
	else if (e.button === 2) {
		Input.mouse.right.is_down = false;
	}
});

document.addEventListener('mousemove', function(e) {
	const rect = canvas.getBoundingClientRect();
	Input.mouseX = e.clientX - rect.left;
	Input.mouseY = e.clientY - rect.top;
});
