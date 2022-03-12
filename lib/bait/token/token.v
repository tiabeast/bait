module token

pub struct Token {
pub:
	kind Kind
	lit  string
}

pub enum Kind {
	unknown
	eof
	name
	string
	number
	assign // =
	lpar // (
	rpar // )
	lcur // {
	rcur // }
	dot // .
	comma // ,
	amp // &
	key_const
	key_fun
	key_package
	key_return
	key_struct
}

pub const keywords = {
	'const':   Kind.key_const
	'fun':     Kind.key_fun
	'package': Kind.key_package
	'return':  Kind.key_return
	'struct':  Kind.key_struct
}

pub enum Precedence {
	lowest
	call
}

const precedences = build_precedences()

fn build_precedences() []Precedence {
	mut p := []Precedence{len: int(Kind.key_struct)}
	p[Kind.dot] = .call
	return p
}

pub fn (tok Token) precedence() int {
	return int(token.precedences[tok.kind])
}
