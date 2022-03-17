module token

pub struct Token {
pub:
	kind Kind
	lit  string
	pos  Position
}

pub enum Kind {
	unknown
	eof
	name
	string
	char
	number
	plus // +
	minus // -
	mul // *
	div // /
	mod // %
	assign // =
	decl_assign // :=
	plus_assign // +=
	minus_assign // -=
	mul_assign // *=
	div_assign // /=
	mod_assign // %=
	lpar // (
	rpar // )
	lbr // [
	rbr // ]
	lcur // {
	rcur // }
	dot // .
	comma // ,
	colon // :
	semicolon // ;
	amp // &
	eq // ==
	ne // !=
	lt // <
	gt // >
	le // <=
	ge // >=
	key_and
	key_const
	key_else
	key_false
	key_for
	key_fun
	key_if
	key_or
	key_package
	key_return
	key_struct
	key_true
}

pub const keywords = {
	'and':     Kind.key_and
	'const':   Kind.key_const
	'else':    Kind.key_else
	'false':   Kind.key_false
	'for':     Kind.key_for
	'fun':     Kind.key_fun
	'if':      Kind.key_if
	'or':      Kind.key_or
	'package': Kind.key_package
	'return':  Kind.key_return
	'struct':  Kind.key_struct
	'true':    Kind.key_true
}

pub enum Precedence {
	lowest
	cond
	compare
	sum
	product
	call
	index
}

const precedences = build_precedences()

fn build_precedences() []Precedence {
	mut p := []Precedence{len: int(Kind.key_true) + 1}
	p[Kind.lbr] = .index
	p[Kind.dot] = .call
	// * / %
	p[Kind.mul] = .product
	p[Kind.div] = .product
	p[Kind.mod] = .product
	// + -
	p[Kind.plus] = .sum
	p[Kind.minus] = .sum
	// == != < > <= >=
	p[Kind.eq] = .compare
	p[Kind.ne] = .compare
	p[Kind.lt] = .compare
	p[Kind.gt] = .compare
	p[Kind.le] = .compare
	p[Kind.ge] = .compare
	// and or
	p[Kind.key_and] = .cond
	p[Kind.key_or] = .cond
	return p
}

pub fn (t Token) precedence() int {
	return int(token.precedences[t.kind])
}

pub fn (k Kind) is_math_assign() bool {
	return k in [.plus_assign, .minus_assign, .mul_assign, .div_assign, .mod_assign]
}

pub fn (k Kind) cstr() string {
	return match k {
		.plus { '+' }
		.minus { '-' }
		.mul { '*' }
		.div { '/' }
		.mod { '%' }
		.assign { '=' }
		.decl_assign { ':=' }
		.plus_assign { '+=' }
		.minus_assign { '-=' }
		.mul_assign { '*=' }
		.div_assign { '/=' }
		.mod_assign { '%=' }
		.eq { '==' }
		.ne { '!=' }
		.lt { '<' }
		.gt { '>' }
		.le { '<=' }
		.ge { '>=' }
		.key_and { '&&' }
		.key_or { '||' }
		else { k.str() }
	}
}
