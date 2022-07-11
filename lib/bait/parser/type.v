// This file is part of: bait.
// Copyright (c) 2022 Lukas Neubert.
// Use of this code is governed by an MIT License (see LICENSE.md).
module parser

import lib.bait.ast

fn (mut p Parser) parse_type() ast.Type {
	mut typ := ast.void_type
	name := p.tok.lit
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
		else { typ = p.table.placeholder_or_new_type(name) }
	}
	return typ
}
