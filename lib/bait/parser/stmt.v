module parser

import lib.bait.ast

fn (mut p Parser) stmt() ast.Stmt {
	match p.tok.kind {
		.name { return p.assign_or_expr_stmt() }
		.key_return { return p.return_stmt() }
		else { return p.expr_stmt() }
	}
}

fn (mut p Parser) top_level_stmt() ast.Stmt {
	match p.tok.kind {
		.key_const { return p.const_decl() }
		.key_fun { return p.fun_decl() }
		.key_struct { return p.struct_decl() }
		else { p.error('bad toplevel stmt: $p.tok') }
	}
	return ast.EmptyStmt{}
}

fn (mut p Parser) assign_or_expr_stmt() ast.Stmt {
	left := p.expr(0)
	if p.tok.kind in [.assign, .decl_assign] {
		return p.assign_stmt(left)
	}
	return ast.ExprStmt{
		expr: left
	}
}

fn (mut p Parser) assign_stmt(left ast.Expr) ast.AsssignStmt {
	op := p.tok.kind
	p.next()
	right := p.expr(0)
	return ast.AsssignStmt{
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

fn (mut p Parser) fun_decl() ast.FunDecl {
	p.check(.key_fun)
	p.open_scope()

	mut is_method := false
	mut params := []ast.Param{}
	if p.tok.kind == .lpar {
		is_method = true
		p.next()
		rec_name := p.check_name()
		rec_type := p.parse_type().set_nr_amp(1)
		params << ast.Param{
			name: rec_name
			typ: rec_type
		}
		p.scope.register(
			name: rec_name
			typ: rec_type
			auto_deref: true
		)
		p.check(.rpar)
	}
	name := p.prepend_pkg(p.check_name())
	p.check(.lpar)
	params << p.fun_params()
	p.check(.rpar)
	mut return_type := ast.void_type
	if p.tok.kind != .lcur {
		return_type = p.parse_type()
	}
	stmts := p.parse_block_no_scope()
	node := ast.FunDecl{
		name: name
		params: params
		return_type: return_type
		stmts: stmts
		is_method: is_method
	}
	p.table.fns[node.name] = node
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
