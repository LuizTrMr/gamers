package platform_audio

import "core:math"
import "core:math/rand"

RAYLIB :: true

/* NOTE: First Implementation (would allocate only the number of sounds needed for a specific level)
All_Pools :: enum {
	ENEMY_EXPLOSION,
}

Sound_Pool :: struct {
	count : int,
	sounds: []Sound, // TODO: Allocate this somewhere and somehow so it doesn't go to a random place in the heap
}

play_from_pool :: proc(sm: Sound_Manager, which_pool: All_Pools) {
	pool  := sm.pools[ which_pool ]
	sound := rand.choice(pool.sounds[:])
	play_sound(sound)
}

set_sounds_for_pool :: proc(sm: ^Sound_Manager, which_pool: All_Pools, sounds: []Sound) {
	pool := sm.pools[which_pool]
	for i in 0..<pool.count {
		pool.sounds[i] = sounds[i]
	}
}

init_pool :: proc(sm: ^Sound_Manager, which_pool: All_Pools, n: int) {
	sm.pools[which_pool].count = n
}

Sound_Manager :: struct {
	pools: [All_Pools]Sound_Pool,
}
*/

// NOTE: Secound implementation (always allocates the same amount of sounds, no matter the level)

db_to_volume :: proc "contextless" (db: f32) -> f32 { // Source: https://www.youtube.com/watch?v=Vjm--AqG04Y
	return math.pow_f32(10, 0.05 * db)
}

volume_to_db :: proc "contextless" (volume: f32) -> f32 { // Source: https://www.youtube.com/watch?v=Vjm--AqG04Y
	return 20.0 * math.log10_f32(volume) 
}

All_Pools :: enum {
	ENEMY_EXPLOSION,
	paint_splash,
}

Sound_Handle :: distinct u32
Sound_Range :: struct {
	handle: Sound_Handle,
	count : u32,
}

SOUNDS_SIZE :: 128
Sound_Manager :: struct {
	all_sounds: [SOUNDS_SIZE]Sound,
	cursor    : int,
	pools     : [All_Pools]Sound_Range,
	music     : Music,
}

get_from_pool :: proc(sm: ^Sound_Manager, which_pool: All_Pools) -> Sound {
	range := sm.pools[which_pool]
	end   := u32(range.handle) + range.count
	sound := rand.choice( sm.all_sounds[range.handle:end] )
	return sound
}

play_from_pool :: proc(sm: ^Sound_Manager, which_pool: All_Pools) {
	range := sm.pools[which_pool]
	end   := u32(range.handle) + range.count
	sound := rand.choice( sm.all_sounds[range.handle:end] )
	play_sound(sound)
}

set_sounds_for_pool :: proc(sm: ^Sound_Manager, which_pool: All_Pools, sounds: []Sound) {
	n_sounds := len(sounds)
	assert(sm.cursor + n_sounds < SOUNDS_SIZE)

	range: Sound_Range
	range.handle = cast(Sound_Handle) sm.cursor
	range.count  = cast(u32) n_sounds
	sm.pools[which_pool] = range

	for i in 0..<n_sounds {
		sm.all_sounds[sm.cursor+i] = sounds[i]
	}
	sm.cursor += n_sounds 
}
