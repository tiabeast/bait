// This file is part of: bait.
// Copyright (c) 2022 Lukas Neubert.
// Use of this code is governed by an MIT License (see LICENSE.md).
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
	number
	string
	decl_assign // :=
	lpar // (
	rpar // )
	lcur // {
	rcur // }
	minus // -
	comma // ,
	eq // ==
	ne // !=
	lt // <
	gt // >
	le // <=
	ge // >=
	key_else
	key_false
	key_fun
	key_if
	key_true
	__end__
}

pub const keywords = {
	'else':  Kind.key_else
	'false': Kind.key_false
	'fun':   Kind.key_fun
	'if':    Kind.key_if
	'true':  Kind.key_true
}

pub fn (k Kind) vstr() string {
	return match k {
		.minus { '-' }
		.decl_assign { ':=' }
		.eq { '==' }
		.ne { '!=' }
		.lt { '<' }
		.gt { '>' }
		.le { '<=' }
		.ge { '>=' }
		else { k.str() }
	}
}
