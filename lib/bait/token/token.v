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
	assign // =
	decl_assign // :=
	lpar // (
	rpar // )
	lcur // {
	rcur // }
	plus // +
	minus // -
	mul // *
	div // /
	mod // %
	plus_assign // +=
	minus_assign // -=
	mul_assign // *=
	div_assign // /=
	mod_assign // %=
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

pub fn (k Kind) is_math_assign() bool {
	return k in [.plus_assign, .minus_assign, .mul_assign, .div_assign, .mod_assign]
}

pub fn (k Kind) vstr() string {
	return match k {
		.assign { '=' }
		.decl_assign { ':=' }
		.plus { '+' }
		.minus { '-' }
		.mul { '*' }
		.div { '/' }
		.mod { '%' }
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
		else { k.str() }
	}
}
