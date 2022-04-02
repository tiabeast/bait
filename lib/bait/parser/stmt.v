// This file is part of: bait programming language
// Copyright (c) 2022 Lukas Neubert
// Use of this code is governed by an MIT License (see LICENSE.md).
module parser

import lib.bait.ast

fn (mut p Parser) stmt() ast.Stmt {
	match p.tok.kind {
		.name { return p.assign_or_expr_stmt() }
		.key_assert { return p.assert_stmt() }
		.key_for { return p.for_stmt() }
		.key_return { return p.return_stmt() }
		else { return p.expr_stmt() }
	}
}

fn (mut p Parser) top_level_stmt() ast.Stmt {
	match p.tok.kind {
		.key_const { return p.const_decl() }
		.key_fun { return p.fun_decl() }
		.key_global { return p.global_decl() }
		.key_struct { return p.struct_decl() }
		else { p.error('bad toplevel stmt: $p.tok') }
	}
	return ast.EmptyStmt{}
}

fn (mut p Parser) assert_stmt() ast.AssertStmt {
	pos := p.tok.pos
	p.check(.key_assert)
	expr := p.expr(0)
	return ast.AssertStmt{
		pos: pos
		expr: expr
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
	if left is ast.Ident {
		if op == .decl_assign {
			p.scope.register(ast.ScopeObject{ name: left.name })
		}
	}
	return ast.AssignStmt{
		op: op
		left: left
		right: right
	}
}

fn (mut p Parser) const_decl() ast.ConstDecl {
	p.check(.key_const)
	name := p.check_name()
	p.check(.assign)
	expr := p.expr(0)
	p.table.global_scope.register(ast.ScopeObject{ name: name })
	return ast.ConstDecl{
		name: name
		expr: expr
	}
}

fn (mut p Parser) expr_stmt() ast.ExprStmt {
	return ast.ExprStmt{
		expr: p.expr(0)
	}
}

fn (mut p Parser) for_stmt() ast.Stmt {
	p.check(.key_for)
	p.inside_for_cond = true
	p.open_scope()
	if p.peek_tok.kind == .decl_assign {
		init := p.assign_or_expr_stmt()
		p.check(.semicolon)
		cond := p.expr(0)
		p.check(.semicolon)
		inc := p.stmt()
		p.inside_for_cond = false
		stmts := p.parse_block_no_scope()
		return ast.ForClassicLoop{
			init: init
			cond: cond
			inc: inc
			stmts: stmts
		}
	} else {
		cond := p.expr(0)
		p.inside_for_cond = false
		stmts := p.parse_block_no_scope()
		return ast.ForLoop{
			cond: cond
			stmts: stmts
		}
	}
}

fn (mut p Parser) fun_decl() ast.FunDecl {
	p.check(.key_fun)
	p.open_scope()

	mut is_method := false
	mut params := []ast.Param{}
	if p.tok.kind == .lpar {
		is_method = true
		p.next()
		rec_name := p.check_name()
		rec_type := p.parse_type()
		params << ast.Param{
			name: rec_name
			typ: rec_type
		}
		p.scope.register(
			name: rec_name
			typ: rec_type
		)
		p.check(.rpar)
	}
	mut name := p.check_name()
	is_test := p.in_test_file && name.starts_with('test_')
	name = p.prepend_pkg(name)
	p.check(.lpar)
	params << p.fun_params()
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
		is_method: is_method
		is_test: is_test
	}
	if is_method {
		mut rec_sym := p.table.get_type_symbol(params[0].typ)
		rec_sym.methods << node
	} else {
		p.table.fns[node.name] = node
	}
	node.stmts = stmts
	p.close_scope()
	return node
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
		p.scope.register(
			name: name
			typ: typ
		)
		if p.tok.kind != .rpar {
			p.check(.comma)
		}
	}
	return params
}

fn (mut p Parser) global_decl() ast.GlobalDecl {
	p.check(.key_global)
	name := p.check_name()
	typ := p.parse_type()
	p.check(.assign)
	expr := p.expr(0)
	p.scope.register(ast.ScopeObject{ name: name, typ: typ, is_global: true })
	return ast.GlobalDecl{
		name: name
		typ: typ
		expr: expr
	}
}

fn (mut p Parser) package_decl() ast.PackageDecl {
	p.check(.key_package)
	name := p.check_name()
	p.pkg_name = name
	return ast.PackageDecl{
		name: name
	}
}

fn (mut p Parser) return_stmt() ast.Return {
	p.check(.key_return)
	if p.tok.kind == .rcur {
		return ast.Return{}
	}
	expr := p.expr(0)
	return ast.Return{
		expr: expr
	}
}

fn (mut p Parser) struct_decl() ast.StructDecl {
	p.check(.key_struct)
	name := p.check_name()
	p.check(.lcur)
	mut fields := []ast.StructField{}
	for p.tok.kind != .rcur {
		field_name := p.check_name()
		typ := p.parse_type()
		fields << ast.StructField{
			name: field_name
			typ: typ
		}
	}
	p.check(.rcur)
	tsym := ast.TypeSymbol{
		kind: .struct_
		name: name
		info: ast.StructInfo{
			fields: fields
		}
	}
	p.table.register_type_symbol(tsym)
	return ast.StructDecl{}
}
