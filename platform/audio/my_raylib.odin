#+build !js
package platform_audio

import rl "vendor:raylib"

when PLATFORM == "RAYLIB" {
	Sound :: rl.Sound
	Music :: rl.Music

	init :: proc() {
		rl.InitAudioDevice()
	}

	play_sound :: proc(sound: Sound) {
		rl.PlaySound(sound)
	}

	sound_set_volume :: proc(sound: Sound, volume: f32) {
		rl.SetSoundVolume(sound, volume)
	}

	sound_set_pitch :: proc(sound: Sound, pitch: f32) {
		rl.SetSoundPitch(sound, pitch)
	}

	load_sound :: proc(path: string) -> Sound {
		return rl.LoadSound( cstring(raw_data(path)) )
	}

	load_music :: proc(path: string) -> Music {
		return rl.LoadMusicStream( cstring(raw_data(path)) )
	}

	play_music :: proc(music: Music) {
		rl.PlayMusicStream(music)
	}

	is_music_playing :: proc(music: Music) -> bool {
		return rl.IsMusicStreamPlaying(music)
	}

	update_music :: proc(music: Music) {
		rl.UpdateMusicStream(music)
	}
}
