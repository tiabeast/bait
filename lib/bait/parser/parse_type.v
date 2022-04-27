// This file is part of: bait programming language
// Copyright (c) 2022 Lukas Neubert
// Use of this code is governed by an MIT License (see LICENSE.md).
module parser

import lib.bait.ast

fn (mut p Parser) parse_type() ast.Type {
	mut nr_amp := 0
	for p.tok.kind == .amp {
		nr_amp++
		p.next()
	}
	if p.tok.kind == .lbr {
		p.check(.lbr)
		p.check(.rbr)
		arr_type := p.parse_type()
		idx := p.table.find_or_register_array(arr_type)
		return ast.new_type(idx)
	}
	if p.tok.kind == .key_fun {
		return p.parse_fun_type('')
	}
	mut typ := ast.void_type
	mut name := p.tok.lit
	if p.expr_pkg.len > 0 {
		name = p.expr_pkg + '.' + name
		p.expr_pkg = ''
	} else if name !in p.table.type_idxs && !name.contains('.') {
		name = p.prepend_pkg(name)
	}
	p.next()
	match name {
		'i8' { typ = ast.i8_type }
		'i16' { typ = ast.i16_type }
		'i32' { typ = ast.i32_type }
		'i64' { typ = ast.i64_type }
		'u8' { typ = ast.u8_type }
		'u16' { typ = ast.u16_type }
		'u32' { typ = ast.u32_type }
		'u64' { typ = ast.u64_type }
		'f32' { typ = ast.f32_type }
		'f64' { typ = ast.f64_type }
		'bool' { typ = ast.bool_type }
		'string' { typ = ast.string_type }
		'map' { typ = p.parse_map_type() }
		else { typ = p.table.placeholder_or_new_type(name) }
	}

	if nr_amp > 0 {
		typ = typ.set_nr_amp(nr_amp)
	}
	return typ
}

fn (mut p Parser) parse_map_type() ast.Type {
	if p.tok.kind != .lbr {
		return ast.map_type
	}
	p.check(.lbr)
	key_type := p.parse_type()
	p.check(.rbr)
	val_type := p.parse_type()
	idx := p.table.find_or_register_map(key_type, val_type)
	return ast.new_type(idx)
}

fn (mut p Parser) parse_fun_type(name string) ast.Type {
	p.next()
	p.check(.lpar)
	params := p.fun_params()
	p.check(.rpar)
	mut return_type := ast.void_type
	if p.tok.pos.line_nr == p.prev_tok.pos.line_nr {
		return_type = p.parse_type()
	}
	node := ast.FunDecl{
		name: name
		params: params
		return_type: return_type
	}
	idx := p.table.find_or_register_fun_type(node)
	return ast.new_type(idx)
}
