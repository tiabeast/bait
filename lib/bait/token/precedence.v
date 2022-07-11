// This file is part of: bait.
// Copyright (c) 2022 Lukas Neubert.
// Use of this code is governed by an MIT License (see LICENSE.md).
module token

pub enum Precedence {
	lowest
	compare
	sum
	product
}

const precedences = build_precedences()

fn build_precedences() []Precedence {
	mut p := []Precedence{len: int(Kind.__end__)}
	// == != < > <= >=
	p[Kind.eq] = .compare
	p[Kind.ne] = .compare
	p[Kind.lt] = .compare
	p[Kind.gt] = .compare
	p[Kind.le] = .compare
	p[Kind.ge] = .compare
	// + -
	p[Kind.plus] = .sum
	p[Kind.minus] = .sum
	// * / %
	p[Kind.mul] = .product
	p[Kind.div] = .product
	p[Kind.mod] = .product
	return p
}

pub fn (t Token) precedence() int {
	return int(token.precedences[t.kind])
}
