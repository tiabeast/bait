// This file is part of: bait.
// Copyright (c) 2022 Lukas Neubert.
// Use of this code is governed by an MIT License (see LICENSE.md).
module parser

import lib.bait.ast

fn (mut p Parser) expr() ast.Expr {
	mut node := ast.empty_expr()
	match p.tok.kind {
		.name { node = p.name_expr() }
		.string { node = p.string_literal() }
		else { p.error('invalid expression: $p.tok') }
	}
	return node
}

fn (mut p Parser) call_expr() ast.CallExpr {
	name := p.check_name()
	p.check(.lpar)
	args := p.call_args()
	p.check(.rpar)
	return ast.CallExpr{
		name: name
		args: args
	}
}

fn (mut p Parser) call_args() []ast.Expr {
	mut args := []ast.Expr{}
	for p.tok.kind != .rpar {
		expr := p.expr()
		args << expr
		if p.tok.kind != .rpar {
			p.check(.comma)
		}
	}
	return args
}

fn (mut p Parser) ident() ast.Ident {
	name := p.check_name()
	return ast.Ident{
		name: name
	}
}

fn (mut p Parser) name_expr() ast.Expr {
	if p.peek_tok.kind == .lpar {
		return p.call_expr()
	}
	return p.ident()
}

fn (mut p Parser) string_literal() ast.StringLiteral {
	val := p.tok.lit
	p.next()
	return ast.StringLiteral{
		val: val
	}
}
