// This file is part of: bait.
// Copyright (c) 2022 Lukas Neubert.
// Use of this code is governed by an MIT License (see LICENSE.md).
module ast

[heap]
pub struct Table {
pub mut:
	funs    map[string]FunDecl
	indexes map[string]int
	symbols []TypeSymbol
}

pub fn new_table() &Table {
	mut t := &Table{}
	t.register_builtin_type_symbols()
	return t
}

pub fn (t &Table) get_type_symbol(typ Type) TypeSymbol {
	idx := typ.idx()
	return t.symbols[idx]
}

pub fn (mut t Table) register_type_symbol(sym TypeSymbol) int {
	new_idx := t.symbols.len
	t.symbols << sym
	t.indexes[sym.name] = new_idx
	return new_idx
}

pub fn (mut t Table) add_placeholder_type(name string) int {
	sym := TypeSymbol{
		kind: .placeholder
		name: name
	}
	return t.register_type_symbol(sym)
}

pub fn (mut t Table) placeholder_or_new_type(name string) Type {
	mut idx := t.indexes[name]
	if idx == 0 {
		idx = t.add_placeholder_type(name)
	}
	return new_type(idx)
}
