module checker

import lib.bait.ast

pub struct Checker {
pub mut:
	table  &ast.Table
	errors []string
mut:
	pkg_name string
}

pub fn (mut c Checker) check_files(files []&ast.File) {
	for f in files {
		c.check(f)
	}
}

fn (mut c Checker) check(file &ast.File) {
	c.stmts(file.stmts)
}

fn (mut c Checker) stmts(stmts []ast.Stmt) {
	for stmt in stmts {
		c.stmt(stmt)
	}
}

fn (mut c Checker) stmt(node ast.Stmt) {
	match mut node {
		ast.EmptyStmt {}
		ast.ExprStmt { c.expr(node.expr) }
		ast.FunDecl { c.fun_decl(node) }
		ast.PackageDecl { c.package_decl(node) }
		ast.StructDecl { c.struct_decl(node) }
	}
}

fn (mut c Checker) expr(node ast.Expr) ast.Type {
	match mut node {
		ast.EmptyExpr { panic('found empty expr') }
		ast.CallExpr { return c.call_expr(node) }
		ast.Ident { return c.ident(node) }
		ast.SelectorExpr { return c.selector_expr(mut node) }
		ast.StringLiteral { return ast.string_type }
	}
	return ast.void_type
}

fn (mut c Checker) fun_decl(node ast.FunDecl) {
	c.stmts(node.stmts)
}

fn (mut c Checker) package_decl(node ast.PackageDecl) {
	c.pkg_name = node.name
}

fn (mut c Checker) struct_decl(node ast.StructDecl) {
}

fn (mut c Checker) call_expr(node ast.CallExpr) ast.Type {
	name := node.name
	mut found := false
	if node.lang == .c || name in c.table.fns {
		found = true
	}
	if !found {
		c.error('unknown function: $name')
	}
	c.call_args(node.args)
	return ast.void_type
}

fn (mut c Checker) call_args(args []ast.CallArg) {
	for a in args {
		c.expr(a.expr)
	}
}

fn (mut c Checker) ident(node ast.Ident) ast.Type {
	return ast.void_type
}

fn (mut c Checker) selector_expr(mut node ast.SelectorExpr) ast.Type {
	typ := c.expr(node.expr)
	fsym := c.table.get_type_symbol(typ)
	match fsym.info {
		ast.StructInfo {
			for f in fsym.info.fields {
				if node.field_name == f.name {
					node.field_type = f.typ
					return f.typ
				}
			}
		}
		ast.OtherInfo {}
	}
	return node.field_type
}

fn (mut c Checker) error(msg string) {
	c.errors << msg
}
