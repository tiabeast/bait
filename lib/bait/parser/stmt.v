module parser

import lib.bait.ast

fn (mut p Parser) stmt() ast.Stmt {
	match p.tok.kind {
		.name {
			return p.expr_stmt()
		}
		else {
			return p.expr_stmt()
		}
	}
}

fn (mut p Parser) top_level_stmt() ast.Stmt {
	match p.tok.kind {
		.key_fun {
			return p.fun_decl()
		}
		.key_struct {
			return p.struct_decl()
		}
		else {
			p.error('bad toplevel stmt: $p.tok')
		}
	}
	return ast.EmptyStmt{}
}

fn (mut p Parser) expr_stmt() ast.ExprStmt {
	return ast.ExprStmt{
		expr: p.expr(0)
	}
}

fn (mut p Parser) fun_decl() ast.FunDecl {
	p.check(.key_fun)
	p.open_scope()
	name := p.prepend_pkg(p.check_name())
	p.check(.lpar)
	params := p.fun_params()
	p.check(.rpar)
	stmts := p.parse_block_no_scope()
	node := ast.FunDecl{
		name: name
		params: params
		stmts: stmts
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
