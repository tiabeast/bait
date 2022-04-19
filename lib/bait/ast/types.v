// This file is part of: bait.
// Copyright (c) 2022 Lukas Neubert.
// Use of this code is governed by an MIT License (see LICENSE.md).
module ast

pub type Type = int

pub type TypeInfo = ArrayInfo | MapInfo | OtherInfo | StructInfo

[heap]
pub struct TypeSymbol {
pub mut:
	kind    TypeKind
	methods []FunDecl
pub:
	name       string
	parent_idx int
	info       TypeInfo
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
	array
	struct_
	map
}

pub enum Language {
	bait
	c
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
	array_idx
	map_idx
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
	array_type  = new_builtin_type(.array_idx)
	map_type    = new_builtin_type(.map_idx)
)

const builtin_struct_types = [
	int(TypeIdx.string_idx),
	int(TypeIdx.array_idx),
	int(TypeIdx.map_idx),
]

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
	t.register_type_symbol(kind: .array, name: 'array')
	t.register_type_symbol(kind: .map, name: 'map')
}

fn new_builtin_type(tidx TypeIdx) Type {
	return new_type(int(tidx))
}

pub fn new_type(idx int) Type {
	if idx < 1 || idx > 65535 {
		panic('type index must be between 1 and 65535')
	}
	return idx
}

pub fn (t Type) idx() int {
	return u16(t) & 0xffff
}

pub fn (t Type) set_nr_amp(nr int) Type {
	return int(t) & 0xfff0ffff | (nr << 16)
}

pub fn (t Type) nr_amp() int {
	return (int(t) >> 16) & 0xf
}

pub fn (sym TypeSymbol) get_method(name string) ?FunDecl {
	for m in sym.methods {
		if m.name == name {
			return m
		}
	}
	return none
}

pub fn (sym TypeSymbol) has_method(name string) bool {
	sym.get_method(name) or { return false }
	return true
}

pub struct OtherInfo {}

pub struct ArrayInfo {
pub:
	elem_type Type
}

pub struct MapInfo {
pub mut:
	key_type Type
	val_type Type
}

pub struct StructInfo {
pub:
	fields []StructField
}
