// This file is part of: bait.
// Copyright (c) 2022 Lukas Neubert.
// Use of this code is governed by an MIT License (see LICENSE.md).
module parser

import lib.bait.ast

fn (mut p Parser) top_level_stmt() ast.Stmt {
	match p.tok.kind {
		.key_fun { return p.fun_decl() }
		else { p.error('bad toplevel stmt: $p.tok') }
	}
	return ast.EmptyStmt{}
}

fn (mut p Parser) stmt() ast.Stmt {
	match p.tok.kind {
		.name { return p.assign_or_expr_stmt() }
		else { return p.expr_stmt() }
	}
}

fn (mut p Parser) assign_or_expr_stmt() ast.Stmt {
	left := p.expr(0)
	if p.tok.kind in [.assign, .decl_assign] || p.tok.kind.is_math_assign() {
		return p.partial_assign_stmt(left)
	}
	return ast.ExprStmt{
		expr: left
	}
}

fn (mut p Parser) partial_assign_stmt(left ast.Expr) ast.AssignStmt {
	op := p.tok.kind
	p.next()
	right := p.expr(0)
	return ast.AssignStmt{
		op: op
		left: left
		right: right
	}
}

fn (mut p Parser) fun_decl() ast.FunDecl {
	p.check(.key_fun)
	p.open_scope()
	name := p.check_name()
	p.check(.lpar)
	params := p.fun_params()
	p.check(.rpar)
	mut return_type := ast.void_type
	if p.tok.kind != .lcur {
		return_type = p.parse_type()
	}
	stmts := p.parse_block_no_scope()
	mut node := ast.FunDecl{
		name: name
		params: params
		return_type: return_type
	}
	p.table.funs[node.name] = node
	node.stmts = stmts
	p.close_scope()
	return node
}

fn (mut p Parser) expr_stmt() ast.ExprStmt {
	return ast.ExprStmt{
		expr: p.expr(0)
	}
}

fn (mut p Parser) fun_params() []ast.Param {
	mut params := []ast.Param{}
	for p.tok.kind != .rpar {
		name := p.check_name()
		typ := p.parse_type()
		params << ast.Param{
			name: name
			typ: typ
		}
		if p.tok.kind != .rpar {
			p.check(.comma)
		}
	}
	return params
}
