#+build windows

package platform

import "core:fmt"
import "core:strings"
import  "core:os"
import os2 "core:os/os2"

_create_or_open :: proc(path: string) -> (os.Handle, os.Error) {
	return os.open(path, os.O_WRONLY|os.O_TRUNC|os.O_CREATE)
}

create_file_if_needed :: proc(path: string) {
	if !os2.exists(path) {
		_, err := os2.create(path)
		assert(err == nil, fmt.tprint(err))
	}
}

create_directory_if_needed :: proc(path: string) {
	if !os2.exists(path) {
		err := os2.make_directory(path)
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
