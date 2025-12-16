package gamers_plex

import "core:fmt"

panicf :: proc(format: string, args: ..any, loc := #caller_location) {
	panic(fmt.tprintfln(format, args), loc=loc)
}
