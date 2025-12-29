#+build darwin
#+private

package platform

import "core:fmt"
import "core:strings"
import  "core:os/os2"
import  "core:os"

_create_or_open :: proc(path: string) -> (os.Handle, os.Error) {
	return os.open(path, os.O_WRONLY|os.O_TRUNC|os.O_CREATE, mode=0o666)
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
	strings.write_string(&sb, "/Mac_Build/")
	create_directory_if_needed(strings.to_string(sb))

	strings.write_string(&sb, name)
	strings.write_string(&sb, ".app")
	create_directory_if_needed(strings.to_string(sb))

	// TODO: Icon?

	strings.write_string(&sb, "/Contents/")
	create_directory_if_needed(strings.to_string(sb))

	strings.write_string(&sb, "Info.plist")
	create_file_if_needed(strings.to_string(sb))

	// TODO: `otool -l GoLucky/Mac_Build/GoLucky.app/Contents/MacOS/GoLucky | grep -A3 LC_BUILD_VERSION` to grap the `minos` value
	minos :: "13.0"
	contents := fmt.tprintfln(`<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>CFBundleName</key>
	<string>%v</string>

	<key>CFBundleExecutable</key>
	<string>%v</string>

	<key>CFBundleIdentifier</key>
	<string>%v</string>

	<key>CFBundlePackageType</key>
	<string>APPL</string>

	<key>CFBundleVersion</key>
	<string>%v.%v.%v</string>

	<key>CFBundleShortVersionString</key>
	<string>%v.%v.%v</string>

	<key>LSMinimumSystemVersion</key>
	<string>%v</string>
</dict>
</plist>`,
		name, name, identifier, version_first, version_second, version_third, version_first, version_second, version_third, minos
	)
	err2 := os2.write_entire_file(strings.to_string(sb), transmute([]u8)contents)
	assert( err2 == nil )

	move_to_parent_directory :: proc(sb: ^strings.Builder) {
		if len(sb.buf) > 0 do strings.pop_byte(sb)
		for len(sb.buf) > 0 && sb.buf[len(sb.buf)-1] != '/' do strings.pop_byte(sb)
	}

	move_to_parent_directory(&sb)

	strings.write_string(&sb, "/MacOS/")
	create_directory_if_needed(strings.to_string(sb))

	move_to_parent_directory(&sb)
	strings.write_string(&sb, "Frameworks/")
	create_directory_if_needed(strings.to_string(sb))
}
