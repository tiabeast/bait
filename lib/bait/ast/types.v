// This file is part of: bait.
// Copyright (c) 2022 Lukas Neubert.
// Use of this code is governed by an MIT License (see LICENSE.md).
module ast

type Type = int

pub struct TypeSymbol {
pub mut:
	kind TypeKind
pub:
	name       string
	parent_idx int
}

pub enum TypeKind {
	placeholder
	void
	i8
	i16
	i32
	i64
	u8
	u16
	u32
	u64
	f32
	f64
	bool
	string
}

enum TypeIdx {
	void_idx = 1
	i8_idx
	i16_idx
	i32_idx
	i64_idx
	u8_idx
	u16_idx
	u32_idx
	u64_idx
	f32_idx
	f64_idx
	bool_idx
	string_idx
}

pub const (
	void_type   = new_builtin_type(.void_idx)
	i8_type     = new_builtin_type(.i8_idx)
	i16_type    = new_builtin_type(.i16_idx)
	i32_type    = new_builtin_type(.i32_idx)
	i64_type    = new_builtin_type(.i64_idx)
	u8_type     = new_builtin_type(.u8_idx)
	u16_type    = new_builtin_type(.u16_idx)
	u32_type    = new_builtin_type(.u32_idx)
	u64_type    = new_builtin_type(.u64_idx)
	f32_type    = new_builtin_type(.f32_idx)
	f64_type    = new_builtin_type(.f64_idx)
	bool_type   = new_builtin_type(.bool_idx)
	string_type = new_builtin_type(.string_idx)
)

fn (mut t Table) register_builtin_type_symbols() {
	t.register_type_symbol(kind: .placeholder, name: 'placeholder')
	t.register_type_symbol(kind: .void, name: 'void')
	t.register_type_symbol(kind: .i8, name: 'i8')
	t.register_type_symbol(kind: .i16, name: 'i16')
	t.register_type_symbol(kind: .i32, name: 'i32')
	t.register_type_symbol(kind: .i64, name: 'i64')
	t.register_type_symbol(kind: .u8, name: 'u8')
	t.register_type_symbol(kind: .u16, name: 'u16')
	t.register_type_symbol(kind: .u32, name: 'u32')
	t.register_type_symbol(kind: .u64, name: 'u64')
	t.register_type_symbol(kind: .f32, name: 'f32')
	t.register_type_symbol(kind: .f64, name: 'f64')
	t.register_type_symbol(kind: .bool, name: 'bool')
	t.register_type_symbol(kind: .string, name: 'string')
}

fn new_type(idx int) Type {
	if idx < 1 || idx > 65535 {
		panic('type index must be between 1 and 65535')
	}
	return idx
}

fn new_builtin_type(tidx TypeIdx) Type {
	return new_type(int(tidx))
}

pub fn (t Type) idx() int {
	return u16(t) & 0xffff
}
