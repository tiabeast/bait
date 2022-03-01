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
	dot // .
	comma // ,
	lpar // (
	rpar // )
	lcur // {
	rcur // }
	amp // &
	key_fun
	key_package
	key_struct
}

pub const keywords = {
	'fun':     Kind.key_fun
	'package': Kind.key_package
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
