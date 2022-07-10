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
	lpar // (
	rpar // )
	lcur // {
	rcur // }
	key_fun
	__end__
}

pub const keywords = {
	'fun': Kind.key_fun
}
