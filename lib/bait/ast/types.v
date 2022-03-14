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
	byte
	i8
	i16
	i32
	i64
	bool
	string
	struct_
}

pub enum Language {
	bait
	c
}

const (
	void_type_idx   = 1
	byte_type_idx   = 2
	i8_type_idx     = 3
	i16_type_idx    = 4
	i32_type_idx    = 5
	i64_type_idx    = 6
	bool_type_idx   = 7
	string_type_idx = 8
)

pub const (
	void_type   = new_type(void_type_idx)
	byte_type   = new_type(byte_type_idx)
	i8_type     = new_type(i8_type_idx)
	i16_type    = new_type(i16_type_idx)
	i32_type    = new_type(i32_type_idx)
	i64_type    = new_type(i64_type_idx)
	bool_type   = new_type(bool_type_idx)
	string_type = new_type(string_type_idx)
)

fn (mut t Table) register_builtin_type_symbols() {
	t.register_type_symbol(kind: .placeholder, name: 'placeholder')
	t.register_type_symbol(kind: .void, name: 'void')
	t.register_type_symbol(kind: .byte, name: 'byte')
	t.register_type_symbol(kind: .i8, name: 'i8')
	t.register_type_symbol(kind: .i16, name: 'i16')
	t.register_type_symbol(kind: .i32, name: 'i32')
	t.register_type_symbol(kind: .i64, name: 'i64')
	t.register_type_symbol(kind: .bool, name: 'bool')
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
