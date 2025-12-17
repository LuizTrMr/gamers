package gamers_plex

import "base:intrinsics"
import "base:runtime"

import "core:math/bits"
import "core:fmt"
import "core:mem"
import "core:strings"
import "core:os"
import "core:reflect"
import "core:strconv"
import "core:log"

// TODO:
//  - Convert the structs in the game from serder to .plex type

Serializer_Config :: struct {
	float_precision: int,
}
default_serializer_config :: Serializer_Config{
	float_precision = 4,
}

serialize_to_file_any :: proc(a: any, path: string, config: Serializer_Config = default_serializer_config, loc := #caller_location) -> mem.Allocator_Error
{
	if !strings.has_suffix(path, ".plex") {
		panic(fmt.tprintfln("Path `%v` needs to be a .plex file!", path))
	}

	builder := strings.builder_make(context.temp_allocator) or_return
	serialize_to_builder_any(a, &builder, 0, config)
	contents := strings.to_string(builder)
	ok := os.write_entire_file(path, transmute([]byte) contents)
	assert(ok, fmt.tprintfln(ERROR + ": Failed to write serialized string to file `%v`", path), loc)
	return nil
}

serialize_to_file :: proc(s: $T, path: string, config: Serializer_Config = default_serializer_config, loc := #caller_location) -> mem.Allocator_Error
where intrinsics.type_is_struct(T) {
	if !strings.has_suffix(path, ".plex") {
		panic(fmt.tprintfln("Path `%v` needs to be a .plex file!", path))
	}

	builder := strings.builder_make(context.temp_allocator) or_return
	serialize_to_builder(s, &builder, 0, config)
	contents := strings.to_string(builder)
	ok := os.write_entire_file(path, transmute([]byte) contents)
	assert(ok, fmt.tprintfln(ERROR + ": Failed to write serialized string to file `%v`", path), loc)
	return nil
}

serialize_to_builder :: proc(s: $T, sb: ^strings.Builder, indentation: int, config: Serializer_Config = default_serializer_config)
where intrinsics.type_is_struct(T) {
	strings.write_string(sb, "{\n")
	for field, i in reflect.struct_fields_zipped(T) {
		if ok, err := contains_tag(field.tag, "deprecated")  ; ok && err == nil do continue
		if ok, err := contains_tag(field.tag, "no_serialize"); ok && err == nil do continue

		indent_pls(sb, 4)
		strings.write_string(sb, field.name)
		strings.write_byte(sb, ASSIGN_TOKEN)
		strings.write_byte(sb, ' ')

		field_value := reflect.struct_field_value_by_name(s, field.name)
		serialize_to_builder_any(field_value, sb, 4, config)
	}
	strings.write_byte(sb, '}')
}

deserialize_from_file :: proc(s: ^$T, path: string, allocator: mem.Allocator) -> mem.Allocator_Error
where intrinsics.type_is_struct(T) {
	if !strings.has_suffix(path, ".plex") {
		panic(fmt.tprintfln("Path `%v` needs to be a .plex file!", path))
	}

	contents, ok := os.read_entire_file(path, context.temp_allocator)
	assert(ok, fmt.tprintfln(ERROR + ": Could not read file `%v`", path))
	t := tokenizer_make(path, string(contents))
	tokenize(&t)
	parser := parser_make(t, path, allocator)

	return deserialize_from_parser_any(s, &parser)
}

// `label` helps when debugging
deserialize_from_data :: proc(s: ^$T, data: []byte, label: string, allocator: mem.Allocator) -> mem.Allocator_Error
where intrinsics.type_is_struct(T) {
	t := tokenizer_make(label, string(data))
	tokenize(&t)
	parser := parser_make(t, label, allocator)

	deserialize_from_parser_any(s, &parser)
	return nil
}

@(private="file")
serialize_to_builder_any :: proc(a: any, sb: ^strings.Builder, indentation: int = 0, config: Serializer_Config) {
	assert(a != nil, "a is `nil`")

	ti := reflect.type_info_base( type_info_of(a.id) )
	if should_indent(sb) do indent_pls(sb, indentation)
	#partial switch info in ti.variant {
		case: panic( fmt.tprintf("Not yet implemented: %v\n", info) )
		case reflect.Type_Info_Enumerated_Array:
			index_ti  := reflect.type_info_base(info.index)
			enum_type := index_ti.variant.(reflect.Type_Info_Enum)

			if !info.is_sparse {
				if info.count == 0 {
					strings.write_string(sb, "nil\n")
					return
				}

				strings.write_byte(sb, '{')
				strings.write_byte(sb, '\n')
				for i in 0..<info.count {
					key := enum_type.names[i]
					indent_pls(sb, indentation+4)
					strings.write_byte(sb, '.')
					strings.write_string(sb, key)
					strings.write_byte(sb, ASSIGN_TOKEN)
					strings.write_byte(sb, ' ')

					data := uintptr(a.data) + uintptr(i*info.elem_size)
					serialize_to_builder_any(any{rawptr(data), info.elem.id}, sb, indentation+4, config)
				}
			} else {
				count := len(enum_type.values)
				if count == 0 {
					strings.write_string(sb, "nil\n")
					return
				}

				strings.write_byte(sb, '{')
				strings.write_byte(sb, '\n')
				sum := 0
				for i in 0..<count {
					key := enum_type.names[i]
					indent_pls(sb, indentation+4)
					strings.write_byte(sb, '.')
					strings.write_string(sb, key)
					strings.write_byte(sb, ASSIGN_TOKEN)
					strings.write_byte(sb, ' ')

					if i != 0 {
						sum += int(enum_type.values[i]) - int(enum_type.values[i-1])
					}
					data := uintptr(a.data) + uintptr(sum*info.elem_size)
					serialize_to_builder_any(any{rawptr(data), info.elem.id}, sb, indentation+4, config)
				}

			}
			
			indent_pls(sb, indentation)
			strings.write_byte(sb, '}')

		case reflect.Type_Info_Bit_Set:
			is_bit_set_different_endian_to_platform :: proc(ti: ^runtime.Type_Info) -> bool {
				if ti == nil {
					return false
				}
				t := runtime.type_info_base(ti)
				#partial switch info in t.variant {
					case runtime.Type_Info_Integer:
					switch info.endianness {
						case .Platform: return false
						case .Little:   return ODIN_ENDIAN != .Little
						case .Big:      return ODIN_ENDIAN != .Big
					}
				}
				return false
			}

			strings.write_byte(sb, '{')
			strings.write_byte(sb, '\n')

			bit_data: u64 = 0
			bit_size := u64(8*ti.size)
			do_byte_swap := is_bit_set_different_endian_to_platform(info.underlying)
			switch bit_size {
				case  0: panic("Don't know how to handle this case")
				case  8:
					x := (^u8)(a.data)^
					bit_data = u64(x)
				case 16:
					x := (^u16)(a.data)^
					if do_byte_swap do x = bits.byte_swap(x)
					bit_data = u64(x)
				case 32:
					x := (^u32)(a.data)^
					if do_byte_swap do x = bits.byte_swap(x)
					bit_data = u64(x)
				case 64:
					x := (^u64)(a.data)^
					if do_byte_swap do x = bits.byte_swap(x)
					bit_data = u64(x)
				}

				for i in info.lower..=info.upper {
					mask: u64 = 1 << u64(i)
					if bit_data & mask != 0 {
						fields := reflect.enum_fields_zipped(info.elem.id)
						for field in fields {
							if u64(field.value) == u64(i) {
								indent_pls(sb, indentation+4)
								strings.write_byte(sb, '.')
								strings.write_string(sb, field.name)
								strings.write_string(sb, ",\n")
								break
							}
						}
					}
				}
				indent_pls(sb, indentation)
				strings.write_byte(sb, '}')
			
		case reflect.Type_Info_Dynamic_Array:
			array := cast(^mem.Raw_Dynamic_Array) a.data
			serialize_slice(sb, indentation, array.data, info.elem, array.len, config)

		case reflect.Type_Info_Slice:
			slice := cast(^mem.Raw_Slice) a.data
			serialize_slice(sb, indentation, slice.data, info.elem, slice.len, config)

		case reflect.Type_Info_Array:
			strings.write_byte(sb, '{')
			strings.write_byte(sb, '\n')

			for i in 0..<info.count {
				data_address := uintptr(a.data) + uintptr(i*info.elem_size)
				indent_pls(sb, indentation+4)
				serialize_to_builder_any(any{rawptr(data_address), info.elem.id}, sb, indentation+4, config)
			}

			indent_pls(sb, indentation)
			strings.write_byte(sb, '}')

		case reflect.Type_Info_Union:
			panic("Don't use unions pls")
			/*
			assert(len(info.variants) > 0 || a.data != nil, "Shit is empty")

			tag_address := uintptr(a.data) + info.tag_offset
			tag_any := any{rawptr(tag_address), info.tag_type.id}

			tag: i64 = -1
			switch i in tag_any {
				case u8:   tag = i64(i)
				case i8:   tag = i64(i)
				case u16:  tag = i64(i)
				case i16:  tag = i64(i)
				case u32:  tag = i64(i)
				case i32:  tag = i64(i)
				case u64:  tag = i64(i)
				case i64:  tag = i64(i)
				case: panic(fmt.tprintfln("Invalid union tag type: %v", i))
			}

			if !info.no_nil {
				if tag == 0 {
					strings.write_string(sb, "nil")
					break
				}
				tag -= 1
			}
			id := info.variants[tag].id

			strings.write_byte(sb, '(')
			reflect.write_type_builder(sb, info.variants[tag])
			strings.write_byte(sb, ')')

			serialize_to_builder_any(any{a.data, id}, sb, indentation, config)
			*/

		case reflect.Type_Info_Struct:
			strings.write_byte(sb, '{')
			strings.write_byte(sb, '\n')

			for field, i in reflect.struct_fields_zipped(a.id) {
				if ok, err := contains_tag(field.tag, "deprecated")  ; ok && err == nil do continue
				if ok, err := contains_tag(field.tag, "no_serialize"); ok && err == nil do continue
				indent_pls(sb, indentation+4)
				strings.write_string(sb, field.name)
				strings.write_byte(sb, ASSIGN_TOKEN)
				strings.write_byte(sb, ' ')

				field_value := reflect.struct_field_value_by_name(a, field.name)
				serialize_to_builder_any(field_value, sb, indentation+4, config)
			}

			indent_pls(sb, indentation)
			strings.write_byte(sb, '}')

		case reflect.Type_Info_Enum:
			strings.write_byte(sb, '.')
			strings.write_string(sb, reflect.enum_string(a))

		case reflect.Type_Info_String:
			strings.write_byte(sb, '"')
			switch s in a {
				case string : strings.write_string(sb, s)
				case cstring: strings.write_string(sb, string(s))
			}
			strings.write_byte(sb, '"')

		case reflect.Type_Info_Boolean:
			val: bool
			switch b in a {
				case bool: val = bool(b)
				case b8  : val = bool(b)
				case b16 : val = bool(b)
				case b32 : val = bool(b)
				case b64 : val = bool(b)
			}
			strings.write_string(sb, val ? "true" : "false")

		case reflect.Type_Info_Integer:
			a := reflect.any_core(a)
			switch i in a {
			case int:
				#assert(size_of(int) <= 8)
				len := strings.write_int(sb, i, 10)
			case uint:
				#assert(size_of(uint) <= 8)
				strings.write_uint(sb, i, 10)
			case uintptr:
				#assert(size_of(uint) <= 8)
				strings.write_uint(sb, uint(i), 10)

			case i8:
				strings.write_int(sb, int(i), 10)
			case u8:
				strings.write_uint(sb, uint(i), 10)

			case i16:
				strings.write_int(sb, int(i), 10)
			case i16le:
				strings.write_int(sb, int(i), 10)
			case i16be:
				strings.write_int(sb, int(i), 10)

			case u16:
				strings.write_uint(sb, uint(i), 10)
			case u16le:
				strings.write_uint(sb, uint(i), 10)
			case u16be:
				strings.write_uint(sb, uint(i), 10)

			case i32:
				strings.write_int(sb, int(i), 10)
			case i32le:
				strings.write_int(sb, int(i), 10)
			case i32be:
				strings.write_int(sb, int(i), 10)
			case u32:
				strings.write_uint(sb, uint(i), 10)
			case u32le:
				strings.write_uint(sb, uint(i), 10)
			case u32be:
				strings.write_uint(sb, uint(i), 10)

			case i64:
				strings.write_i64(sb, i, 10)
			case i64le:
				strings.write_i64(sb, i64(i), 10)
			case i64be:
				strings.write_i64(sb, i64(i), 10)

			case u64:
				strings.write_u64(sb, i, 10)
			case u64le:
				strings.write_u64(sb, u64(i), 10)
			case u64be:
				strings.write_u64(sb, u64(i), 10)

			case i128:
				buf: [40]byte
				s := strconv.write_bits_128(buf[:], u128(i), 10, true, 128, base_10_digits, {})
				strings.write_string(sb, s)
			case i128le:
				buf: [40]byte
				s := strconv.write_bits_128(buf[:], u128(i), 10, true, 128, base_10_digits, {})
				strings.write_string(sb, s)
			case i128be:
				buf: [40]byte
				s := strconv.write_bits_128(buf[:], u128(i), 10, true, 128, base_10_digits, {})
				strings.write_string(sb, s)
			case u128:
				buf: [40]byte
				s := strconv.write_u128(buf[:], i, 10)
				strings.write_string(sb, s)
			case u128le:
				buf: [40]byte
				s := strconv.write_u128(buf[:], u128(i), 10)
				strings.write_string(sb, s)
			case u128be:
				buf: [40]byte
				s := strconv.write_u128(buf[:], u128(i), 10)
				strings.write_string(sb, s)

			case: panic( fmt.tprintf("Not implemented: %v\n", a.id) )
			}


		case reflect.Type_Info_Float:
			a := reflect.any_core(a)
			buf: [32]u8
			str: string
			switch f in a {
				case f16: str = strconv.ftoa(buf[:], f64(f), 'f', config.float_precision, 16)
				case f32: str = strconv.ftoa(buf[:], f64(f), 'f', config.float_precision, 32)
				case f64: str = strconv.ftoa(buf[:],     f , 'f', config.float_precision, 64)
				case: panic("AAAAAAAA")
			}
			strings.write_string(sb, str)

	}

	strings.write_byte(sb, ',')
	strings.write_byte(sb, '\n')
}


@(private)
deserialize_from_parser_any :: proc(a: any, parser: ^Parser) -> mem.Allocator_Error {
	assert(a != nil, "a is `nil`")
	a := reflect.any_base(a)

	ti := type_info_of(a.id)
	if !reflect.is_pointer(ti) || ti.id == rawptr {
		panic("NOT A POINTER")
	}
	underlying_id := ti.variant.(reflect.Type_Info_Pointer).elem.id

	data := any{(^rawptr)(a.data)^, underlying_id}
	deserialize_from_parser(data, parser)
	assert(parser.curr_token.kind == .End)
	return nil
}

@(private="file")
assign_bool :: proc(val: any, b: bool) {
	v := reflect.any_core(val)
	switch &dst in v {
	case bool: dst = bool(b)
	case b16 : dst = b16(b)
	case b32 : dst = b32(b)
	case b64 : dst = b64(b)
	case     : panic( fmt.tprintfln("UNIMPLEMENTED: %v", v.id) )
	}
}

@(private="file")
assign_int :: proc(v: any, i: $T) {
	v := reflect.any_core(v)
	switch &dst in v {
		case int : dst = cast(int)  i
		case uint: dst = cast(uint) i

		case i8: dst = cast(i8) i
		case u8: dst = cast(u8) i

		case i16  : dst = cast(i16)   i
		case i16be: dst = cast(i16be) i
		case i16le: dst = cast(i16le) i
		case u16  : dst = cast(u16)   i
		case u16be: dst = cast(u16be) i
		case u16le: dst = cast(u16le) i

		case i32  : dst = cast(i32)   i
		case i32be: dst = cast(i32be) i
		case i32le: dst = cast(i32le) i
		case u32  : dst = cast(u32)   i
		case u32be: dst = cast(u32be) i
		case u32le: dst = cast(u32le) i

		case i64  : dst = cast(i64)   i
		case i64be: dst = cast(i64be) i
		case i64le: dst = cast(i64le) i
		case u64  : dst = cast(u64)   i
		case u64be: dst = cast(u64be) i
		case u64le: dst = cast(u64le) i

		case i128  : dst = cast(i128)   i
		case i128le: dst = cast(i128le) i
		case i128be: dst = cast(i128be) i
		case u128  : dst = cast(u128)   i
		case u128le: dst = cast(u128le) i
		case u128be: dst = cast(u128be) i

		case uintptr: dst = cast(uintptr) i

		case: assert(false, fmt.tprintf("UNIMPLEMENTED: %v\n", v.id))
	}
}

@(private="file")
assign_float :: proc(v: any, f: $T) {
	v := reflect.any_core(v)
	switch &dst in v {
		case f16  : dst = cast(f16)   f
		case f16be: dst = cast(f16be) f
		case f16le: dst = cast(f16le) f

		case f32  : dst = cast(f32)   f
		case f32be: dst = cast(f32be) f
		case f32le: dst = cast(f32le) f

		case f64  : dst = cast(f64)   f
		case f64be: dst = cast(f64be) f
		case f64le: dst = cast(f64le) f

		case:
			panic("Something went terribly wrong")
	}
}

@(private="file")
deserialize_from_parser :: proc(a: any, parser: ^Parser) {
	assert(a != nil, fmt.tprintfln("a is `nil` while trying to parse: %v", parser.path))

	ti := reflect.type_info_base( type_info_of(a.id) )
	#partial switch info in ti.variant {
		case: panic( fmt.tprintf("UNIMPLEMENTED: %v\n", info) )

		case reflect.Type_Info_Dynamic_Array:
			token := advance(parser)
			if token.text == "nil" do break
			expect(parser^,  token.kind == .Curly_Bracket_Open )

			n := count_number_of_elements_in_slice(parser, info.elem)
			data := bytes_make(info.elem.size * n, info.elem.align, parser.allocator)
			raw := (^mem.Raw_Dynamic_Array)(a.data)
			raw.data = raw_data(data)
			raw.len = n
			raw.cap = n
			raw.allocator = parser.allocator
			assign_array(raw.data, info.elem, uintptr(n), parser)
			expect(parser^,  advance(parser).kind == .Curly_Bracket_Close)
			
		case reflect.Type_Info_Slice:
			token := advance(parser)
			if token.text == "nil" do break
			expect(parser^,  token.kind == .Curly_Bracket_Open)

			n := count_number_of_elements_in_slice(parser, info.elem)
			data := bytes_make(info.elem.size * n, info.elem.align, parser.allocator)
			raw := (^mem.Raw_Slice)(a.data)
			raw.data = raw_data(data)
			raw.len = n
			assign_array(raw.data, info.elem, uintptr(n), parser)
			expect(parser^,  advance(parser).kind == .Curly_Bracket_Close)


		case reflect.Type_Info_Enumerated_Array:
			token := advance(parser)
			if token.text == "nil" do break
			expect(parser^, token.kind == .Curly_Bracket_Open)

			index_ti  := reflect.type_info_base(info.index)
			enum_type := index_ti.variant.(reflect.Type_Info_Enum)
			for parser.curr_token.kind != .Curly_Bracket_Close {
				token = advance(parser)
				expect(parser^, token.kind == .Dot, fmt.tprintf("Token = %v", token))

				token = advance(parser)
				expect(parser^, token.kind == .Stream, fmt.tprintf("Token = %v", token))
				key := token.text

				index: int
				found: bool
				for name, i in enum_type.names {
					if key == name {
						index = int(enum_type.values[i] - info.min_value)
						found = true
						break
					}
				}
				expect(parser^, found, fmt.tprintf("Couldn't find a value for key: %v", key) )
				expect(parser^, index < info.count, fmt.tprintf("I don't know what happened here, key value: ", key) )

				expect(parser^, advance(parser).kind == .Assign )
				index_ptr := rawptr(uintptr(a.data) + uintptr(index*info.elem_size))
				index_any := any{index_ptr, info.elem.id}

				deserialize_from_parser(index_any, parser)
			}

			expect(parser^, advance(parser).kind == .Curly_Bracket_Close )

		case reflect.Type_Info_Bit_Set:
			if _, ok := reflect.type_info_base( type_info_of(info.elem.id) ).variant.(reflect.Type_Info_Enum); !ok {
				panic("Can only deserialize Bit Sets for enums")
			}

			token := advance(parser)
			expect(parser^, token.kind == .Curly_Bracket_Open)

			bit_data: u64 = 0
			for parser.curr_token.kind != .Curly_Bracket_Close {
				token := advance(parser)
				expect(parser^, token.kind == .Dot, fmt.tprintf("Token = %v", token))

				token = advance(parser)
				expect(parser^, token.kind == .Stream, fmt.tprintf("Token = %v", token))
				enum_value, ok := reflect.enum_from_name_any(info.elem.id, token.text)
				assert(ok)

				u := cast(u64) enum_value // O que eu fui nerd aqui é brincadeira tá
				bit_data |= 1 << u

				expect(parser^, advance(parser).kind == .Comma, fmt.tprintf("Token = %v", token))
			}
			expect(parser^, advance(parser).kind == .Curly_Bracket_Close)

			bit_size := u64(8*ti.size)
			switch bit_size {
				case 8:
					b := u8(bit_data)
					(^u8)(a.data)^ = b
				case 16:
					b := u16(bit_data)
					(^u16)(a.data)^ = b
				case 32:
					b := u32(bit_data)
					(^u32)(a.data)^ = b
				case 64:
					b := bit_data
					(^u64)(a.data)^ = b

				case 0: panic("Size is 0")
				case  : panic("unknown bit_size size")
			}

		case reflect.Type_Info_Union:
			panic("Don't use unions please")
			// token := advance(parser)
			// if token.text == "nil" do return

			// expect(parser^, token.kind == .Parenthesis_Open)

			// type_token := advance(parser)
			// expect(parser^, type_token.kind == .Stream, fmt.tprintf("Token = %v", token))
			// expect(parser^, advance(parser).kind == .Parenthesis_Close)
			
			// type_s := type_token.text

			// expect(parser^, len(info.variants) > 1, "Union only has 1 variant")

			// for variant, i in info.variants {
			// 	sb := strings.builder_make(context.temp_allocator)
			// 	reflect.write_type_builder(&sb, variant)

			// 	variant_s := strings.to_string(sb)
			// 	if variant_s == type_s {
			// 		variant_any := any{a.data, variant.id}
			// 		deserialize_from_parser(variant_any, parser)

			// 		raw_tag := i
			// 		if !info.no_nil { raw_tag += 1 }

			// 		tag := any{rawptr(uintptr(a.data) + info.tag_offset), info.tag_type.id}
			// 		assign_int(tag, raw_tag)

			// 		break
			// 	}
			// }
			// expect_comma = false
			
		case reflect.Type_Info_Enum:
			token := advance(parser)
			expect(parser^, token.kind == .Dot, fmt.tprintf("Token = %v", token))

			token = advance(parser)
			expect(parser^, token.kind == .Stream, fmt.tprintf("Token = %v", token))
			found: bool
			for name, i in info.names {
				if name == token.text {
					found = true
					assign_int(a, info.values[i])
					break
				}
			}
			expect(parser^, found, fmt.tprintf("Could not find value: %s for enum of type %v", token.text, a.id))

		case reflect.Type_Info_String:
			token := advance(parser)
			expect(parser^, token.kind == .Double_Quotes, fmt.tprintf("Token = %v", token))
			token = advance(parser)
			switch &dst in a {
				case string:
					dst = token.text
				case cstring: panic("Deserialization of `cstring` is not supported!")
			}
			token = advance(parser)
			expect(parser^, token.kind == .Double_Quotes, fmt.tprintf("Token = %v", token))

		case reflect.Type_Info_Struct:
			token := advance(parser)
			expect(parser^, token.kind == .Curly_Bracket_Open, fmt.tprintf("Token = %v", token))
			for parser.curr_token.kind != .Curly_Bracket_Close {
				token := advance(parser)
				expect(parser^, token.kind == .Stream, fmt.tprintf("Token = %v", token))
				key := token.text

				found: bool
				for field, i in reflect.struct_fields_zipped(a.id) {
					if field.name != key do continue

					found = true
					expect(parser^,  advance(parser).kind == .Assign)
					if contains, err := contains_tag(field.tag, "no_serialize"); contains && err == nil {
						// NOTE: This is only here in the case that you had a member who was being serialized
						//       and then you added the "no_serialize" tag to it. Otherwise you would have to
						//       re-serialize or manually remove the field which would be ass.
						eat_value(parser)
					} else if !contains {
						data_ptr := rawptr( uintptr(a.data) + field.offset )
						field_any := any{data_ptr, field.type.id}
						deserialize_from_parser(field_any, parser)
					}
					else {
						panic(fmt.tprintfln("Error:", err))
					}
				}
				expect(parser^, found, fmt.tprintf("Could not find field: %s for struct of type %v", key, a.id))
			}
			expect(parser^, advance(parser).kind == .Curly_Bracket_Close, fmt.tprintf("Token = %v"))

		case reflect.Type_Info_Boolean:
			value := parse_boolean(parser)
			assign_bool(a, value)
			
		case reflect.Type_Info_Integer:
			i := parse_integer(parser)
			assign_int(a, i)

		case reflect.Type_Info_Float:
			f := parse_float(parser)
			assign_float(a, f)

		case reflect.Type_Info_Array:
			token := advance(parser)
			expect(parser^, token.kind == .Curly_Bracket_Open)
			for i in 0..<info.count {
				elem_ptr := rawptr(uintptr(a.data) + uintptr(i) * uintptr(info.elem_size))
				elem := any{elem_ptr, info.elem.id}
				deserialize_from_parser(elem, parser)
			}
			expect(parser^, advance(parser).kind == .Curly_Bracket_Close)
	}
	if parser.curr_token.kind != .End { // `.End` only if this is the whole struct
		token := advance(parser)
		expect(parser^, token.kind == .Comma, fmt.tprintf("Token = %v", token))
	}
}

eat_value :: proc(parser: ^Parser) {
	token := advance(parser)
	#partial switch token.kind {
	case .Curly_Bracket_Open:
		// Skip the whole thing
		curly_bracket_stack_current := parser.curly_bracket_stack
		for parser.curly_bracket_stack >= curly_bracket_stack_current {
			advance(parser)
		}
	case .Parenthesis_Open:
		panic("Don't use unions!!!!!!!")

	case .Dot:
		token := advance(parser)
		expect(parser^, token.kind == .Stream, fmt.tprintf("Token = %v", token))
	case .Double_Quotes:
		token := advance(parser)
		expect(parser^, token.kind == .Stream, fmt.tprintf("Token = %v", token))

		token = advance(parser)
		expect(parser^, token.kind == .Double_Quotes, fmt.tprintf("Token = %v", token))
	case .Stream:
		// Do nothing, we already "skipped" by the `advance` at the beginning
		break
		
	case: panicf("Kind: %v", token.kind)
	}
	token = advance(parser)
	expect(parser^, token.kind == .Comma)
}

Token_Kind :: enum {
	None,

	Curly_Bracket_Open,
	Curly_Bracket_Close,

	Parenthesis_Open,
	Parenthesis_Close,

	Assign,
	Dot,
	Comma,
	Double_Quotes,
	Stream,
	Newline,
	End,
}
ASSIGN_TOKEN :: '='

Token :: struct {
	kind : Token_Kind,
	start: int,
	text : string,
}

Tokenizer :: struct {
	data  : string,
	filepath: string,

	cursor: int,
	tokens: [dynamic]Token,

	is_inside_string: bool,
}

Parser :: struct {
	curly_bracket_stack: int,
	cursor: int,
	t: Tokenizer,
	curr_token: Token,
	allocator: mem.Allocator,
	path: string,
}

line_of :: proc(t: Tokenizer, index: int) -> (n: int) {
	n += 1 // NOTE: Line starts at 1 not 0
	for i in 0..<index {
		if t.data[i] == '\n' do n += 1
	}
	return
}

grab_line :: proc(t: Tokenizer, index: int) -> string {
	i := index
	start: int
	for i > -1 {
		if t.data[i] == '\n' {
			start = i+1
			break
		}
		i -= 1
	}

	i = index
	end := len(t.data)
	for i < len(t.data) {
		if t.data[i] == '\n' {
			end = i
			break
		}
		i += 1
	}

	return string(t.data[start:end])
}

tokenizer_error :: proc(t: Tokenizer, message: string) {
	source_file_index := t.cursor-1
	fmt.print(ERROR+": "); fmt.println(message)
	fmt.printfln("File `%v` at line `%v`:\n%v",
				 t.filepath,
				 line_of(t, source_file_index), // NOTE: `line_of` and `grab_line` are subpar quality
				 grab_line(t, source_file_index))
	os.exit(1)
}

expect :: proc(parser: Parser, condition: bool, message: string = "", loc := #caller_location, expr := #caller_expression(condition)) {
	if !condition {
		source_file_index := parser.t.tokens[parser.cursor-1].start
		fmt.printfln(ERROR + " at %v:", loc)
		fmt.printfln("Failed to parse file `%v` at line `%v`:\n%v",
					 parser.path,
					 line_of(parser.t, source_file_index), // NOTE: `line_of` and `grab_line` are subpar quality
					 grab_line(parser.t, source_file_index))

		fmt.printf("Parser expects that `%v`, ", expr)
		if message == "" do fmt.println("but that was not the case!")
		else             do fmt.println(message)
		os.exit(1)
	}
}

parser_make :: proc(t: Tokenizer, path: string, allocator: mem.Allocator) -> Parser {
	parser: Parser
	parser.t = t
	parser.curr_token = parser.t.tokens[parser.cursor]
	parser.path = path
	parser.allocator = allocator
	return parser
}

advance :: proc(parser: ^Parser) -> Token {
	token := parser.curr_token

	if      token.kind == .Curly_Bracket_Open  do parser.curly_bracket_stack += 1
	else if token.kind == .Curly_Bracket_Close do parser.curly_bracket_stack -= 1

	parser.cursor += 1
	parser.curr_token = parser.t.tokens[parser.cursor]

	return token
}

tokenizer_make :: proc(path: string, data: string) -> Tokenizer {
	t: Tokenizer
	replaced, was_allocation := strings.replace_all(data, "\r\n", "\n", context.temp_allocator)
	t.data = replaced
	t.filepath = path
	t.tokens = make([dynamic]Token, context.temp_allocator)
	return t
}

grab_stream :: proc(t: ^Tokenizer) -> string {
	is_inside_array :: proc(chars: []u8, char: u8) -> bool {
		for c in chars {
			if c == char do return true
		}
		return false
	}

	start := t.cursor
	characters_to_sentry: []u8
	if !t.is_inside_string {
		characters_to_sentry = []u8{' ', '\t', '\n', '{', '}', '[', ']', '(', ')', '=', '#', ','}
	}
	else {
		characters_to_sentry = []u8{'"', '\n'}
	}
	loop: for t.cursor < len(t.data) {
		if is_inside_array(characters_to_sentry, t.data[t.cursor]) {
			break loop
		}
		else {
			t.cursor += 1
		}
	}
	stream := t.data[start:t.cursor]
	return stream
}

tokenize :: proc(t: ^Tokenizer) {
	for t.cursor < len(t.data) {
		found := true
		token: Token
		token.start = t.cursor
		switch t.data[t.cursor] {
			case ' ', '\t': t.cursor += 1; found = false

			case '#':
				found = false
				cursor := t.cursor+1
				if cursor < len(t.data) {
					next_byte := t.data[cursor]
					if next_byte == '=' { // Multi-line
						comment_stack := 1
						cursor += 1
						for comment_stack > 0 {
							if cursor >= len(t.data)-2 {
								tokenizer_error(t^, "Forgot to close multi-line comment")
							}
							if string(t.data[cursor:cursor+2]) == "=#" {
								comment_stack -= 1
								cursor += 1
							}
							else if string(t.data[cursor:cursor+2]) == "#=" {
								comment_stack += 1
								cursor += 1
							}
							cursor += 1
						}
					}
					else {
						for cursor < len(t.data) && t.data[cursor] != '\n' do cursor += 1
					}
				}
				t.cursor = cursor

			case '\n':
				if t.is_inside_string {
					tokenizer_error(t^, "Forgot to close string literal")
				}
				found = false
				t.cursor += 1

			case '{':
				token.kind = .Curly_Bracket_Open
				token.text = string(t.data[t.cursor:t.cursor+1])
				t.cursor += 1

			case '}':
				token.kind = .Curly_Bracket_Close
				token.text = string(t.data[t.cursor:t.cursor+1])
				t.cursor += 1

			case '(':
				token.kind = .Parenthesis_Open
				token.text = string(t.data[t.cursor:t.cursor+1])
				t.cursor += 1

			case ')':
				token.kind = .Parenthesis_Close
				token.text = string(t.data[t.cursor:t.cursor+1])
				t.cursor += 1

			case '=':
				token.kind = .Assign
				token.text = string(t.data[t.cursor:t.cursor+1])
				t.cursor += 1

			case '.':
				token.kind = .Dot
				token.text = string(t.data[t.cursor:t.cursor+1])
				t.cursor += 1

			case ',':
				token.kind = .Comma
				token.text = string(t.data[t.cursor:t.cursor+1])
				t.cursor += 1

			case '"':
				token.kind = .Double_Quotes
				token.text = string(t.data[t.cursor:t.cursor+1])
				t.cursor += 1
				t.is_inside_string = !t.is_inside_string

			case '\\':
				assert(t.is_inside_string)
				scan_escape(t)
				t.cursor += 1

			case: // Grab the value
				token.text  = grab_stream(t)
				token.kind  = .Stream
		}

		if found {
			append(&t.tokens, token)
		}
	}
	append(&t.tokens, Token{.End, t.cursor, ""})
}

scan_escape :: proc(t: ^Tokenizer) {
	t.cursor += 1
	panicf("We are not prepared for this type of advanced technology: %v", t.data[t.cursor])
}

@(private="file")
bytes_make :: proc(size, alignment: int, allocator: mem.Allocator, loc := #caller_location) -> []byte {
	b, err := mem.alloc_bytes(size, alignment, allocator, loc)
	assert(err == nil)
	return b
}

ERROR :: "\033[31mERROR\033[0m"

@(private="file")
indent_pls :: #force_inline proc(sb: ^strings.Builder, indentation: int) {
	for _ in 0..<indentation {
		strings.write_byte(sb, ' ')
	}
}

@(private="file")
should_indent :: #force_inline proc(sb: ^strings.Builder) -> bool {
	return len(sb.buf) > 0 && sb.buf[len(sb.buf)-1] == '\n'
}

@(private="file")
serialize_slice :: proc(sb: ^strings.Builder, indentation: int, base: rawptr,
						element_info: ^reflect.Type_Info, length: int, config: Serializer_Config)
{
	if length == 0 {
		strings.write_string(sb, "nil")
	}
	else {
		strings.write_byte(sb, '{')
		strings.write_byte(sb, '\n')
		for i in 0..<length {
			data := uintptr(base) + uintptr(i*element_info.size)
			serialize_to_builder_any(any{rawptr(data), element_info.id}, sb, indentation+4, config)
		}
		indent_pls(sb, indentation)
		strings.write_byte(sb, '}')
	}
}

@(private)
assign_array :: proc(base: rawptr, elem: ^reflect.Type_Info, length: uintptr, parser: ^Parser) {
	for idx: uintptr = 0; idx < length; idx += 1 {
		elem_ptr := rawptr(uintptr(base) + idx*uintptr(elem.size))
		elem := any{elem_ptr, elem.id}
		deserialize_from_parser(elem, parser)
	}
}

@(private)
contains_tag :: proc(struct_tags: reflect.Struct_Tag, tag_name: string) -> (ok: bool, err: mem.Allocator_Error) {
	tags := strings.split(string(struct_tags), " ", context.temp_allocator) or_return
	for t in tags {
		if t == tag_name do return true, nil
	}
	return false, nil
}

// @parsing
@(private)
count_number_of_elements_in_slice :: proc(parser: ^Parser, elem: ^reflect.Type_Info) -> (res:int) { // Bad, would like to dettach the parser from the serder, but this is good for now
	snapshot := parser^
	any_any_data := bytes_make(elem.size*1, elem.align, context.temp_allocator)
	any_any := any{raw_data(any_any_data), elem.id}
	for snapshot.curr_token.kind != .Curly_Bracket_Close && snapshot.curr_token.kind != .End {
		deserialize_from_parser(any_any, &snapshot) // parse slice item
		res += 1
	}
	expect(snapshot, advance(&snapshot).kind == .Curly_Bracket_Close)
	return
}

@(private)
parse_boolean :: proc(parser: ^Parser, loc := #caller_location) -> (res:bool) {
	token := advance(parser)
	expect(parser^, token.kind == .Stream, fmt.tprintf("Token = %v", token))
	switch token.text {
		case "true" : res = true
		case "false": res = false
		case        : panic( fmt.tprintfln("%s is not supported as a boolean value!", token.text) )
	}
	return
}

@(private)
parse_integer :: proc(parser: ^Parser, loc := #caller_location) -> i128 {
	token := advance(parser)
	expect(parser^, token.kind == .Stream, fmt.tprintf("Token = %v", token))
	i, ok := strconv.parse_i128(token.text)
	expect(parser^, ok, fmt.tprintfln("Could not convert: %s into an integer!", token.text))
	return i
}

@(private)
parse_float :: proc(parser: ^Parser, loc := #caller_location) -> f64 {
	token := advance(parser)
	expect(parser^, token.kind == .Stream, fmt.tprintf("Token = %v", token))
	f, ok := strconv.parse_f64(token.text)
	expect(parser^, ok, fmt.tprintfln("Could not convert: %s into a float!", token.text))
	return f
}

base_10_digits := "0123456789"
