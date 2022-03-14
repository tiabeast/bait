module parser

import lib.bait.ast

fn (mut p Parser) parse_type() ast.Type {
	mut nr_amp := 0
	for p.tok.kind == .amp {
		nr_amp++
		p.next()
	}
	mut typ := ast.void_type
	name := p.tok.lit
	p.next()
	match name {
		'byte' {
			typ = ast.byte_type
		}
		'i8' {
			typ = ast.i8_type
		}
		'i16' {
			typ = ast.i16_type
		}
		'i32' {
			typ = ast.i32_type
		}
		'i64' {
			typ = ast.i64_type
		}
		'bool' {
			typ = ast.bool_type
		}
		'string' {
			typ = ast.string_type
		}
		else {
			mut idx := p.table.type_idxs[name]
			if idx == 0 {
				idx = p.table.add_placeholder_type(name)
			}
			typ = ast.new_type(idx)
		}
	}
	if nr_amp > 0 {
		typ = typ.set_nr_amp(nr_amp)
	}
	return typ
}
