#+build windows

package platform

import "core:fmt"
import "core:strings"
import os "core:os/os2"


create_file_if_needed :: proc(path: string) {
	if !os.exists(path) {
		_, err := os.create(path)
		assert(err == nil, fmt.tprint(err))
	}
}

create_directory_if_needed :: proc(path: string) {
	if !os.exists(path) {
		err := os.make_directory(path)
		assert(err == nil, fmt.tprint(err))
	}
}

_create_package :: proc(name: string, identifier: string, version_first, version_second, version_third: int) {
	create_directory_if_needed(name)

	sb := strings.builder_make(context.temp_allocator)
	strings.write_string(&sb, name)
	strings.write_string(&sb, "/Windows_Build/")
	create_directory_if_needed(strings.to_string(sb))

	// strings.write_string(&sb, name)
	// strings.write_byte(&sb, '/')
	// create_directory_if_needed(strings.to_string(sb))

	// TODO: Icon?
}
