// This file is part of: bait.
// Copyright (c) 2022 Lukas Neubert.
// Use of this code is governed by an MIT License (see LICENSE.md).
module parser

import lib.bait.ast

fn (mut p Parser) expr(precedence int) ast.Expr {
	mut node := ast.empty_expr()
	match p.tok.kind {
		.name { node = p.name_expr(.bait) }
		.number { node = p.number_literal() }
		.string { node = p.string_literal() }
		.at { node = p.at_expr() }
		.key_if { node = p.if_expr() }
		.key_true, .key_false { node = p.bool_literal() }
		else { p.error('invalid expression: $p.tok') }
	}
	return p.expr_with_left(node, precedence)
}

fn (mut p Parser) expr_with_left(left_ ast.Expr, precedence int) ast.Expr {
	mut left := left_
	for precedence < p.tok.precedence() {
		if p.tok.kind == .dot {
			left = p.dot_expr(left)
		} else if p.tok.kind in [.plus, .minus, .mul, .div, .mod, .eq, .ne, .lt, .gt, .le, .ge] {
			left = p.infix_expr(left)
		} else {
			return left
		}
	}
	return left
}

fn (mut p Parser) at_expr() ast.Expr {
	lang := p.check_lang_prefix()
	return p.name_expr(lang)
}

fn (mut p Parser) bool_literal() ast.BoolLiteral {
	p.next()
	return ast.BoolLiteral{
		val: p.prev_tok.kind == .key_true
	}
}

fn (mut p Parser) fun_call(lang ast.Language) ast.CallExpr {
	mut name := p.check_name()
	if p.expr_pkg.len > 0 {
		name = '${p.expr_pkg}.$name'
		p.expr_pkg = ''
	}
	p.check(.lpar)
	args := p.call_args()
	p.check(.rpar)
	return ast.CallExpr{
		name: name
		lang: lang
		args: args
	}
}

fn (mut p Parser) method_call(left ast.Expr) ast.CallExpr {
	name := p.check_name()
	p.check(.lpar)
	args := p.call_args()
	p.check(.rpar)
	return ast.CallExpr{
		name: name
		args: args
		left: left
		is_method: true
	}
}

fn (mut p Parser) call_args() []ast.Expr {
	mut args := []ast.Expr{}
	for p.tok.kind != .rpar {
		expr := p.expr(0)
		args << expr
		if p.tok.kind != .rpar {
			p.check(.comma)
		}
	}
	return args
}

fn (mut p Parser) dot_expr(left ast.Expr) ast.Expr {
	p.check(.dot)
	return p.method_call(left)
}

fn (mut p Parser) ident(lang ast.Language) ast.Ident {
	mut name := p.check_name()
	if p.expr_pkg.len > 0 {
		name = '${p.expr_pkg}.$name'
		p.expr_pkg = ''
	}
	return ast.Ident{
		name: name
		lang: lang
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
		cond := p.expr(0)
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

fn (mut p Parser) infix_expr(left ast.Expr) ast.InfixExpr {
	op_tok := p.tok
	p.next()
	right := p.expr(op_tok.precedence())
	return ast.InfixExpr{
		left: left
		right: right
		op: op_tok.kind
	}
}

fn (mut p Parser) name_expr(lang ast.Language) ast.Expr {
	if p.peek_tok.kind == .dot && p.has_import(lang, p.tok.lit) {
		p.expr_pkg = p.tok.lit
		p.next()
		p.next()
	}
	if p.peek_tok.kind == .lpar {
		return p.fun_call(lang)
	}
	return p.ident(lang)
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
