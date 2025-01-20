package gamers_libs

import "base:intrinsics"
import "base:runtime"

import "core:fmt"
import "core:mem"
import "core:strings"
import "core:os"
import "core:reflect"
import "core:strconv"
import "core:log"

// TODO: Use `(` and `)` to put metadata, e.g.: Union type, number of elements of slice

// TODO: Tentar melhorar isso pra eu compartilhar no github com geral
//   - Eu podia adicionar uma constante que diz se vc quer LOGGING ou não, e aí: when LOG do log.infof("Blarg")
//   - E se o parser tivesse uma variável que diz o nome do field que ele tá parseando atualmente pra ter uns logs/asserts/panics melhores?

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
serialize_to_string :: proc(a: any, sb: ^strings.Builder, indentation: int = 0) {
	assert(a != nil, "a is `nil`")

	ti := reflect.type_info_base( type_info_of(a.id) )
	#partial switch info in ti.variant {
		case: panic( fmt.tprintf("Not yet implemented: %v\n", info) )
		case reflect.Type_Info_Enumerated_Array:
			if should_indent(sb) do indent_pls(sb, indentation)

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
					strings.write_string(sb, key)
					strings.write_string(sb, ": ")

					data := uintptr(a.data) + uintptr(i*info.elem_size)
					serialize_to_string(any{rawptr(data), info.elem.id}, sb, indentation+4)
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
					strings.write_string(sb, key)
					strings.write_string(sb, ": ")

					if i != 0 {
						sum += int(enum_type.values[i]) - int(enum_type.values[i-1])
					}
					data := uintptr(a.data) + uintptr(sum*info.elem_size)
					serialize_to_string(any{rawptr(data), info.elem.id}, sb, indentation+4)
				}

			}
			
			indent_pls(sb, indentation)
			strings.write_byte(sb, '}')

		case reflect.Type_Info_Bit_Set: // NOTE: Not handling the possibility of the bit_set endianess being different from the machine
			if should_indent(sb) do indent_pls(sb, indentation)
			strings.write_byte(sb, '{')
			strings.write_byte(sb, '\n')

			bit_data: u64 = 0
			bit_size := u64(8*ti.size)
			switch bit_size {
				case  0: panic("Don't know how to handle this case")
				case  8:
					x := (^u8)(a.data)^
					bit_data = u64(x)
				case 16:
					x := (^u16)(a.data)^
					bit_data = u64(x)
				case 32:
					x := (^u32)(a.data)^
					bit_data = u64(x)
				case 64:
					x := (^u64)(a.data)^
					bit_data = u64(x)
				}

				for i in info.lower..<info.upper {
					mask: u64 = 1 << u64(i)
					if bit_data & mask != 0 {
						fields := reflect.enum_fields_zipped(info.elem.id)
						for field in fields {
							if u64(field.value) == u64(i) {
								indent_pls(sb, indentation+4)
								strings.write_string(sb, field.name)
								strings.write_byte(sb, '\n')
								break
							}
						}
					}
				}

				indent_pls(sb, indentation)
				strings.write_byte(sb, '}')

			
		case reflect.Type_Info_Slice:
			slice := cast(^mem.Raw_Slice) a.data
			if slice.len == 0 {
				strings.write_string(sb, "nil")
			} else {
				if should_indent(sb) do indent_pls(sb, indentation)

				strings.write_byte(sb, '[')
				strings.write_int(sb, int(slice.len))
				strings.write_byte(sb, ']')
				strings.write_byte(sb, '{')
				strings.write_byte(sb, '\n')

				for i in 0..<slice.len {
					data := uintptr(slice.data) + uintptr(i*info.elem_size)
					serialize_to_string(any{rawptr(data), info.elem.id}, sb, indentation+4)
				}

				indent_pls(sb, indentation)
				strings.write_byte(sb, '}')
			}

		case reflect.Type_Info_Array:
			if should_indent(sb) do indent_pls(sb, indentation)
			strings.write_byte(sb, '{')
			strings.write_byte(sb, '\n')

			for i in 0..<info.count {
				data_address := uintptr(a.data) + uintptr(i*info.elem_size)
				indent_pls(sb, indentation+4)
				serialize_to_string(any{rawptr(data_address), info.elem.id}, sb, indentation+4)
			}

			indent_pls(sb, indentation)
			strings.write_byte(sb, '}')

		case reflect.Type_Info_Union:
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

			serialize_to_string(any{a.data, id}, sb, indentation)

		case reflect.Type_Info_Struct:
			if should_indent(sb) do indent_pls(sb, indentation)
			strings.write_byte(sb, '{')
			strings.write_byte(sb, '\n')

			for field, i in reflect.struct_fields_zipped(a.id) {
				indent_pls(sb, indentation+4)
				strings.write_string(sb, field.name)
				strings.write_byte(sb, ':')
				strings.write_byte(sb, ' ')

				field_value := reflect.struct_field_value_by_name(a, field.name)
				serialize_to_string(field_value, sb, indentation+4)
			}

			indent_pls(sb, indentation)
			strings.write_byte(sb, '}')

		case reflect.Type_Info_Enum:
			strings.write_string(sb, reflect.enum_string(a))

		case reflect.Type_Info_String:
			switch s in a {
				case string : strings.write_string(sb, s)
				case cstring: strings.write_string(sb, string(s))
			}

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
				case i8 : strings.write_int(sb, int(i))
				case i16: strings.write_int(sb, int(i))
				case i32: strings.write_int(sb, int(i))
				case i64: strings.write_int(sb, int(i))
				case int: strings.write_int(sb, i)

				case u8  : strings.write_uint(sb, uint(i))
				case u16 : strings.write_uint(sb, uint(i))
				case u32 : strings.write_uint(sb, uint(i))
				case u64 : strings.write_uint(sb, uint(i))
				case uint: strings.write_uint(sb, i)
				case: panic( fmt.tprintf("Not implemented: %v\n", a.id) )
			}

		case reflect.Type_Info_Float:
			a := reflect.any_core(a)
			switch f in a {
				case f16: strings.write_f16(sb, f, 'f')
				case f32: strings.write_f32(sb, f, 'f')
				case f64: strings.write_f64(sb, f, 'f')
				case: panic("AAAAAAAA")
			}

	}

	strings.write_byte(sb, '\n')
}

serialize_to_file :: proc(a: any, path: string) {
	assert(a != nil, "a is `nil`")

	contents: string
	{
		sb := strings.builder_make(context.temp_allocator)
		serialize_to_string(a, &sb, 0)
		contents = strings.to_string(sb)
	}
	assert(contents != "")

	sb := strings.builder_make(context.temp_allocator)
	strings.write_string(&sb, path)
	strings.write_byte  (&sb, '.')
	reflect.write_typeid(&sb, a.id)

	full_path := strings.to_string(sb)

	ok := os.write_entire_file(full_path, transmute([]byte) contents)
	assert(ok)
}

deserialize_from_file :: proc(a: any, path: string, allocator: Maybe(mem.Allocator)) {
	assert(a != nil, "a is `nil`")
	a := a
	a = reflect.any_base(a)

	ti := type_info_of(a.id)
	if !reflect.is_pointer(ti) || ti.id == rawptr {
		panic("NOT A POINTER")
	}
	underlying_id := ti.variant.(reflect.Type_Info_Pointer).elem.id

	sb := strings.builder_make(context.temp_allocator)

	strings.write_string(&sb, path)
	strings.write_byte(&sb, '.')
	reflect.write_typeid(&sb, underlying_id)

	full_path := strings.to_string(sb)

	contents, ok := os.read_entire_file(full_path, context.temp_allocator)
	assert(ok, fmt.tprintln("Could not read file: ", full_path))

	lexer := lexer_make(string(contents))
	lex(&lexer)

	alloc, is_valid := allocator.?
	if !is_valid do alloc = context.allocator // If `nil` is passed just use context.allocator
	parser := parser_make(lexer, path, alloc)

	data := any{(^rawptr)(a.data)^, underlying_id}
	// log.infof("Start Deserializing type: %v", a.id)
	deserialize_from_string(data, &parser)
	// log.infof("End   Deserializing type: %v", a.id)
	assert(parser.curr_token.kind == .End)
}

@(private="file")
assign_bool :: proc(val: any, b: bool) {
	v := reflect.any_core(val)
	switch &dst in v {
	case bool: dst = bool(b)
	case     : panic( fmt.tprintfln("UNIMPLEMENTED: %v", v.id) )
	}
}

@(private="file")
assign_int :: proc(v: any, i: $T) {
	v := reflect.any_core(v)
	switch &dst in v {
		case i8 : dst = cast(i8 ) i
		case i16: dst = cast(i16) i
		case i32: dst = cast(i32) i
		case i64: dst = cast(i64) i
		case int: dst = cast(int) i

		case u8  : dst = cast(u8  ) i
		case u16 : dst = cast(u16 ) i
		case u32 : dst = cast(u32 ) i
		case u64 : dst = cast(u64 ) i
		case uint: dst = cast(uint) i

		case: assert(false, fmt.tprintf("UNIMPLEMENTED: %v\n", v.id))
	}
}

@(private="file")
assign_float :: proc(v: any, f: $T) {
	v := reflect.any_core(v)
	switch &dst in v {
		case f16: dst = cast(f16) f
		case f32: dst = cast(f32) f
		case f64: dst = cast(f64) f
	}
}

@(private="file")
deserialize_from_string :: proc(a: any, parser: ^Parser) {
	assert(a != nil, "a is `nil`")

	ti := reflect.type_info_base( type_info_of(a.id) )
	#partial switch info in ti.variant {
		case: panic( fmt.tprintf("UNIMPLEMENTED: %v\n", info) )
		case reflect.Type_Info_Enumerated_Array:
			index_ti  := reflect.type_info_base(info.index)
			enum_type := index_ti.variant.(reflect.Type_Info_Enum)

			token := advance(parser)
			if token.text == "nil" do return
			expect(parser^, token.kind == .Curly_Bracket_Open)

			for parser.curr_token.kind != .Curly_Bracket_Close {
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

				expect(parser^, advance(parser).kind == .Column )
				index_ptr := rawptr(uintptr(a.data) + uintptr(index*info.elem_size))
				index_any := any{index_ptr, info.elem.id}

				deserialize_from_string(index_any, parser)
			}

			expect(parser^, advance(parser).kind == .Curly_Bracket_Close )

		case reflect.Type_Info_Pointer:
			if parser.curr_token.text == "nil" {
                advance(parser)
                return
            }

            ptr, err := mem.alloc(info.elem.size, info.elem.align, parser.allocator)
            expect(parser^, err == nil)
	        underlying_id := info.elem.id
            (^rawptr)(a.data)^ = ptr
	        data := any{(^rawptr)(a.data)^, underlying_id}
            deserialize_from_string(data, parser)

		case reflect.Type_Info_Slice:
			assign_array :: proc(base: rawptr, elem: ^reflect.Type_Info, length: uintptr, parser: ^Parser) {
				for idx: uintptr = 0; idx < length; idx += 1 {
					elem_ptr := rawptr(uintptr(base) + idx*uintptr(elem.size))
					elem := any{elem_ptr, elem.id}
					deserialize_from_string(elem, parser)
				}
			}
			token := advance(parser)
			if token.text == "nil" do return

			expect(parser^,  token.kind == .Bracket_Open )
			token = advance(parser)
			expect(parser^, token.kind == .Stream, fmt.tprintf("Token = %v", token))

			n := strconv.atoi(token.text)
			expect(parser^,  advance(parser).kind == .Bracket_Close )
			expect(parser^,  advance(parser).kind == .Curly_Bracket_Open )

			data := bytes_make(info.elem.size * n, info.elem.align, parser.allocator)
			raw := (^mem.Raw_Slice)(a.data)
			raw.data = raw_data(data)
			raw.len = n
			assign_array(raw.data, info.elem, uintptr(n), parser)
			expect(parser^,  advance(parser).kind == .Curly_Bracket_Close)


		case reflect.Type_Info_Bit_Set:
			if _, ok := reflect.type_info_base( type_info_of(info.elem.id) ).variant.(reflect.Type_Info_Enum); !ok {
				panic("Can only deserialize Bit Sets for enums")
			}

			token := advance(parser)
			expect(parser^, token.kind == .Curly_Bracket_Open)

			bit_data: u64 = 0

			value_token := advance(parser)
			expect(parser^, value_token.kind == .Stream, fmt.tprintf("Token = %v", token))

			for value_token.kind != .Curly_Bracket_Close {
				enum_value, ok := reflect.enum_from_name_any(info.elem.id, value_token.text)
				assert(ok)

				u := cast(u64) enum_value // O que eu fui nerd aqui é brincadeira tá
				bit_data |= 1 << u

				value_token = advance(parser)
			}

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
			token := advance(parser)
			if token.text == "nil" do return

			expect(parser^, token.kind == .Parenthesis_Open)

			type_token := advance(parser)
			expect(parser^, type_token.kind == .Stream, fmt.tprintf("Token = %v", token))
			expect(parser^, advance(parser).kind == .Parenthesis_Close)
			
			type_s := type_token.text

			expect(parser^, len(info.variants) > 1, "Union only has 1 variant")

			for variant, i in info.variants {
				sb := strings.builder_make(context.temp_allocator)
				reflect.write_type_builder(&sb, variant)

				variant_s := strings.to_string(sb)
				if variant_s == type_s {
					variant_any := any{a.data, variant.id}
					deserialize_from_string(variant_any, parser)

					raw_tag := i
					if !info.no_nil { raw_tag += 1 }

					tag := any{rawptr(uintptr(a.data) + info.tag_offset), info.tag_type.id}
					assign_int(tag, raw_tag)

					break
				}
			}
			
		case reflect.Type_Info_Enum:
			token := advance(parser)
			expect(parser^, token.kind == .Stream, fmt.tprintf("Token = %v"))
			found: bool
			for name, i in info.names {
				if name == token.text {
					found = true
					assign_int(a, info.values[i])
					break
				}
			}
			if !found do panic(fmt.tprintf("Could not find value: %s for enum of type %v", token.text, a.id))

		case reflect.Type_Info_String:
			token := advance(parser)
			expect(parser^, token.kind == .Stream, fmt.tprintf("Token = %v"))
			switch &dst in a {
				case string:
					dst = token.text
				case cstring: panic("Deserialization of `cstring` is not supported!")
			}

		case reflect.Type_Info_Struct:
			expect(parser^, advance(parser).kind == .Curly_Bracket_Open)

			token := advance(parser)
			for token.kind != .Curly_Bracket_Close {
				expect(parser^, token.kind == .Stream, fmt.tprintf("Token = %v"))
				expect(parser^, parser.curr_token.kind == .Column)
				key := token.text

				found: bool
				for field, i in reflect.struct_fields_zipped(a.id) {
					if field.name != key do continue

					found = true
					expect(parser^,  advance(parser).kind == .Column )
					if field.tag == "no_deserialize" {
						// log.warnf("Don't forget to deserialize the field %v for the %v type", field.name, a) TODO: Do this or nah?
						token := advance(parser)
						if token.kind == .Curly_Bracket_Open {
							// Skip the whole thing
							curly_bracket_stack_current := parser.curly_bracket_stack
							for parser.curly_bracket_stack >= curly_bracket_stack_current {
								advance(parser)
							}
						} else if token.kind != .Stream {
							panic(fmt.tprintfln("Token.kind = %v", token.kind))
						}
					} else {
						data_ptr := rawptr( uintptr(a.data) + field.offset )
						field_any := any{data_ptr, field.type.id}
						deserialize_from_string(field_any, parser)
					}
				}
				expect(parser^, found, fmt.tprintf("Could not find field: %s for struct of type %v", key, a.id))
				token = advance(parser)
			}

		case reflect.Type_Info_Boolean:
			token := advance(parser)
			expect(parser^, token.kind == .Stream, fmt.tprintf("Token = %v"))
			switch token.text {
				case "true" : assign_bool(a, true )
				case "false": assign_bool(a, false)
				case        : panic( fmt.tprintfln("%s is not supported as a boolean value!", token.text) )
			}
			
		case reflect.Type_Info_Integer:
			token := advance(parser)
			expect(parser^, token.kind == .Stream, fmt.tprintf("Token = %v"))
			i, ok := strconv.parse_i128(token.text)
			expect(parser^, ok, fmt.tprintfln("Could not convert: %s into an integer!", token.text))
			assign_int(a, i)

		case reflect.Type_Info_Float:
			token := advance(parser)
			expect(parser^, token.kind == .Stream, fmt.tprintf("Token = %v"))
			f, ok := strconv.parse_f64(token.text)
			assert(ok)
			assign_float(a, f)

		case reflect.Type_Info_Array:
			token := advance(parser)
			expect(parser^, token.kind == .Curly_Bracket_Open)
			for i in 0..<info.count {
				elem_ptr := rawptr(uintptr(a.data) + uintptr(i) * uintptr(info.elem_size))
				elem := any{elem_ptr, info.elem.id}
				deserialize_from_string(elem, parser)
			}
			expect(parser^, advance(parser).kind == .Curly_Bracket_Close)
	}
}

Token_Kind :: enum {
	None,

	Curly_Bracket_Open,
	Curly_Bracket_Close,

	Bracket_Open,
	Bracket_Close,

	Parenthesis_Open,
	Parenthesis_Close,

	Column,
	Stream,
	End,
}

Token :: struct {
	kind : Token_Kind,
	start: int,
	text : string,
}

Lexer :: struct {
	data  : string,
	cursor: int,
	tokens: [dynamic]Token,
}

Parser :: struct {
	curly_bracket_stack: int,
	cursor: int,
	lexer: Lexer,
	curr_token: Token,
	allocator: mem.Allocator,
	path: string,
}

line_of :: proc(lexer: Lexer, index: int) -> (n: int) {
	n += 1 // NOTE: Line starts at 1 not 0
	for i in 0..<index {
		if lexer.data[i] == '\n' do n += 1
	}
	return
}

grab_line :: proc(lexer: Lexer, index: int) -> string {
	i := index
	start: int
	for i > -1 {
		if lexer.data[i] == '\n' {
			start = i+1
			break
		}
		i -= 1
	}

	i = index
	end := len(lexer.data)
	for i < len(lexer.data) {
		if lexer.data[i] == '\n' {
			end = i
			break
		}
		i += 1
	}

	return string(lexer.data[start:end])
}

expect :: proc(parser: Parser, condition: bool, message: string = "", loc := #caller_location, expr := #caller_expression(condition)) {
	if !condition {
		source_file_index := parser.lexer.tokens[parser.cursor-1].start
		fmt.printfln("\033[31mERROR\033[0m at %v:", loc)
		fmt.printfln("Failed to parse file `%v` at line `%v`:\n%v",
					 parser.path,
					 line_of(parser.lexer, source_file_index), // NOTE: `line_of` and `grab_line` are subpar quality
					 grab_line(parser.lexer, source_file_index))

		fmt.printf("Parser expects that `%v`, ", expr)
		if message == "" do fmt.println("but that was not the case!")
		else             do fmt.println(message)
		os.exit(1)
	}
}

parser_make :: proc(lexer: Lexer, path: string, allocator: mem.Allocator) -> Parser {
	parser: Parser
	parser.lexer = lexer
	parser.curr_token = parser.lexer.tokens[parser.cursor]
	parser.path = path
	parser.allocator = allocator
	return parser
}

advance :: proc(parser: ^Parser) -> Token {
	token := parser.curr_token

	if      token.kind == .Curly_Bracket_Open  do parser.curly_bracket_stack += 1
	else if token.kind == .Curly_Bracket_Close do parser.curly_bracket_stack -= 1

	parser.cursor += 1
	parser.curr_token = parser.lexer.tokens[parser.cursor]

	return token
}

lexer_make :: proc(data: string) -> Lexer {
	lexer: Lexer
	lexer.data = data
	lexer.tokens = make([dynamic]Token, context.temp_allocator)
	return lexer
}

grab_stream :: proc(lexer: ^Lexer) -> string {
	start := lexer.cursor
	loop: for lexer.cursor < len(lexer.data) {
		switch lexer.data[lexer.cursor] {
			case ' ', '\t', '\n', '{', '}', '[', ']', '(', ')', ':', '#': break loop // NOTE: Se eu serializar uma string com um '\n' fudeu
			case: lexer.cursor += 1
		}
	}
	stream := lexer.data[start:lexer.cursor]
	return stream
}

lex :: proc(lexer: ^Lexer) {
	for lexer.cursor < len(lexer.data) {
		found := true
		token: Token
		token.start = lexer.cursor
		switch lexer.data[lexer.cursor] {
			case ' ', '\t', '\n': lexer.cursor += 1; found = false

			case '#':
				lexer.cursor += 1
				next_byte := lexer.data[lexer.cursor]
				found = false
				if next_byte == '=' {
					// Multi-line comment (Currently it cannot be nested)
					lexer.cursor += 1
					for lexer.cursor < len(lexer.data) {
						if lexer.data[lexer.cursor] == '=' && lexer.data[lexer.cursor+1] == '#' {
							lexer.cursor += 2
							break
						}
						lexer.cursor += 1
					}
					if lexer.cursor == len(lexer.data) do panic("Ya forgot to close the multi-line comment ya dumbass")
				} else {
					// Single line comment
					for lexer.data[lexer.cursor] != '\n' do lexer.cursor += 1
				}

			case '{':
				token.kind = .Curly_Bracket_Open
				token.text = string(lexer.data[lexer.cursor:lexer.cursor+1])
				lexer.cursor += 1

			case '}':
				token.kind = .Curly_Bracket_Close
				token.text = string(lexer.data[lexer.cursor:lexer.cursor+1])
				lexer.cursor += 1

			case '[':
				token.kind = .Bracket_Open
				token.text = string(lexer.data[lexer.cursor:lexer.cursor+1])
				lexer.cursor += 1

			case ']':
				token.kind = .Bracket_Close
				token.text = string(lexer.data[lexer.cursor:lexer.cursor+1])
				lexer.cursor += 1

			case '(':
				token.kind = .Parenthesis_Open
				token.text = string(lexer.data[lexer.cursor:lexer.cursor+1])
				lexer.cursor += 1

			case ')':
				token.kind = .Parenthesis_Close
				token.text = string(lexer.data[lexer.cursor:lexer.cursor+1])
				lexer.cursor += 1

			case ':':
				token.kind = .Column
				token.text = string(lexer.data[lexer.cursor:lexer.cursor+1])
				lexer.cursor += 1

			case: // Grab the value
				token.text  = grab_stream(lexer)
				token.kind  = .Stream
		}

		if found {
			append(&lexer.tokens, token)
		}
	}
	append(&lexer.tokens, Token{.End, lexer.cursor, ""})
}

@(private="file")
bytes_make :: proc(size, alignment: int, allocator: mem.Allocator, loc := #caller_location) -> []byte {
	b, berr := mem.alloc_bytes(size, alignment, allocator, loc)
	assert(berr == nil)
	return b
}
