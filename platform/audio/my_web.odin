#+build js
package platform_audio

foreign import plat "web"
foreign plat {
}

Sound :: int
Music :: int

init :: proc() { }

play_sound :: proc(sound: Sound) { }

sound_set_volume :: proc(sound: Sound, volume: f32) { }

sound_set_pitch :: proc(sound: Sound, pitch: f32) { }

load_sound :: proc(path: string) -> Sound {
	return 0
}

load_music :: proc(path: string) -> Music {
	return 0
}

play_music :: proc(music: Music) { }

is_music_playing :: proc(music: Music) -> bool {
	return false
}

update_music :: proc(music: Music) { }
