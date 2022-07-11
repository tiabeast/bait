// This file is part of: bait.
// Copyright (c) 2022 Lukas Neubert.
// Use of this code is governed by an MIT License (see LICENSE.md).
module parser

import lib.bait.ast

fn (mut p Parser) expr() ast.Expr {
	mut node := ast.empty_expr()
	match p.tok.kind {
		.name { node = p.name_expr() }
		.number { node = p.number_literal() }
		.string { node = p.string_literal() }
		.key_if{node=p.if_expr()}
		.key_true, .key_false { node = p.bool_literal() }
		else { p.error('invalid expression: $p.tok') }
	}
	return node
}

fn (mut p Parser) bool_literal() ast.BoolLiteral {
	p.next()
	return ast.BoolLiteral{
		val: p.prev_tok.kind == .key_true
	}
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

fn (mut p Parser) if_expr() ast.IfExpr {
	mut branches := []ast.IfBranch{}
	mut has_else := false
	for {
		if p.tok.kind == .key_else {
			p.next()
			if p.tok.kind == .lcur {
				has_else = true
				stmts := p.parse_block_no_scope()
				branches << ast.IfBranch{
					stmts: stmts
				}
				break
			}
		}
		p.check(.key_if)
		cond := p.expr()
		stmts := p.parse_block_no_scope()
		branches << ast.IfBranch{
			cond: cond
			stmts: stmts
		}
		if p.tok.kind != .key_else {
			break
		}
	}
	return ast.IfExpr{
		has_else: has_else
		branches: branches
	}
}

fn (mut p Parser) name_expr() ast.Expr {
	if p.peek_tok.kind == .lpar {
		return p.call_expr()
	}
	return p.ident()
}

fn (mut p Parser) number_literal() ast.Expr {
	is_neg := p.tok.kind == .minus
	if is_neg {
		p.next()
	}
	mut val := p.tok.lit
	if is_neg {
		val = '-$val'
	}
	p.next()
	if val.contains('.') {
		return ast.FloatLiteral{
			val: val
		}
	}
	return ast.IntegerLiteral{
		val: val
	}
}

fn (mut p Parser) string_literal() ast.StringLiteral {
	val := p.tok.lit
	p.next()
	return ast.StringLiteral{
		val: val
	}
}
