module ast

pub type Type = int

pub type TypeInfo = OtherInfo | StructInfo

pub struct TypeSymbol {
mut:
	kind TypeKind
pub:
	name string
	info TypeInfo
}

pub enum TypeKind {
	placeholder
	void
	string
	struct_
}

pub enum Language {
	bait
	c
}

const (
	void_type_idx   = 1
	string_type_idx = 2
)

pub const (
	void_type   = new_type(void_type_idx)
	string_type = new_type(string_type_idx)
)

fn (mut t Table) register_builtin_type_symbols() {
	t.register_type_symbol(kind: .placeholder)
	t.register_type_symbol(kind: .void, name: 'void')
	t.register_type_symbol(kind: .string, name: 'string')
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

pub fn (t Type) nr_amps() int {
	return (int(t) >> 16) & 0xf
}

pub struct OtherInfo {}

pub struct StructInfo {
pub:
	fields []StructField
}
