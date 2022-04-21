// This file is part of: bait programming language
// Copyright (c) 2022 Lukas Neubert
// Use of this code is governed by an MIT License (see LICENSE.md).
module ast

[heap]
pub struct Table {
pub mut:
	fns          map[string]FunDecl
	type_idxs    map[string]int
	type_symbols []TypeSymbol
	global_scope &Scope
}

pub fn new_table() &Table {
	mut t := &Table{
		global_scope: &Scope{
			parent: 0
		}
	}
	t.register_builtin_type_symbols()
	return t
}

pub fn (t &Table) get_type_symbol(typ Type) &TypeSymbol {
	idx := typ.idx()
	return &t.type_symbols[idx]
}

pub fn (mut t Table) register_type_symbol(sym TypeSymbol) int {
	idx := t.type_idxs[sym.name]
	if idx > 0 {
		existing_sym := t.type_symbols[idx]
		if existing_sym.kind == .placeholder {
			t.type_symbols[idx] = sym
			return idx
		} else if idx in builtin_struct_types {
			mut updated_sym := sym
			updated_sym.kind = existing_sym.kind
			t.type_symbols[idx] = updated_sym
			return idx
		}
	}
	new_idx := t.type_symbols.len
	t.type_symbols << sym
	t.type_idxs[sym.name] = new_idx
	return new_idx
}

pub fn (mut t Table) find_or_register_array(elem_type Type) int {
	elem_sym := t.get_type_symbol(elem_type)
	name := '[]$elem_sym.name'
	idx := t.type_idxs[name]
	if idx > 0 {
		return idx
	}
	sym := TypeSymbol{
		kind: .array
		name: name
		parent_idx: int(TypeIdx.array_idx)
		info: ArrayInfo{
			elem_type: elem_type
		}
	}
	return t.register_type_symbol(sym)
}

pub fn (mut t Table) find_or_register_map(key_type Type, val_type Type) int {
	key_sym := t.get_type_symbol(key_type)
	val_sym := t.get_type_symbol(val_type)
	name := 'map[$key_sym.name]$val_sym.name'
	idx := t.type_idxs[name]
	if idx > 0 {
		return idx
	}
	map_type_sym := TypeSymbol{
		kind: .map
		name: name
		info: MapInfo{
			key_type: key_type
			val_type: val_type
		}
	}
	return t.register_type_symbol(map_type_sym)
}

pub fn (mut t Table) find_or_register_fun_type(f FunDecl) int {
	mut name := f.name
	if name.len == 0 {
		name = 'anon_fn_' + t.fun_type_signature(f)
	}
	existing_idx := t.type_idxs[name]
	if existing_idx > 0 && t.type_symbols[existing_idx].kind != .placeholder {
		return existing_idx
	}
	return t.register_type_symbol(
		kind: .function
		name: name
		info: FunInfo{
			decl: f
		}
	)
}

fn (t &Table) fun_type_signature(f FunDecl) string {
	mut s := ''
	for p in f.params{
		sym := t.get_type_symbol(p.typ)
		s += sym.name
		s += '_'
	}
	rsym:=t.get_type_symbol(f.return_type)
	s+='_'
	s+=rsym.name
	return s
}

pub fn (mut t Table) add_placeholder_type(name string) int {
	sym := TypeSymbol{
		kind: .placeholder
		name: name
	}
	return t.register_type_symbol(sym)
}

pub fn (mut t Table) placeholder_or_new_type(name string) Type {
	mut idx := t.type_idxs[name]
	if idx == 0 {
		idx = t.add_placeholder_type(name)
	}
	return new_type(idx)
}

pub fn (t &Table) get_method(s &TypeSymbol, name string) ?FunDecl {
	mut sym := s
	for {
		if m := sym.get_method(name) {
			return m
		}
		if sym.parent_idx == 0 {
			break
		}
		sym = &t.type_symbols[sym.parent_idx]
	}
	return none
}

pub fn (t &Table) has_method(sym &TypeSymbol, name string) bool {
	t.get_method(sym, name) or { return false }
	return true
}
