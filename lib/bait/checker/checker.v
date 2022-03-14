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

fn (mut c Checker) check(file_ &ast.File) {
	mut file := file_
	c.stmts(mut file.stmts)
}

fn (mut c Checker) stmts(mut stmts []ast.Stmt) {
	for mut stmt in stmts {
		c.stmt(mut stmt)
	}
}

fn (mut c Checker) stmt(mut node ast.Stmt) {
	match mut node {
		ast.EmptyStmt { panic('found empty stmt') }
		ast.AsssignStmt { c.assign_stmt(mut node) }
		ast.ConstDecl { c.const_decl(mut node) }
		ast.ExprStmt { c.expr(mut node.expr) }
		ast.ForStmt { c.for_stmt(mut node) }
		ast.ForClassicStmt { c.for_classic_stmt(mut node) }
		ast.FunDecl { c.fun_decl(mut node) }
		ast.PackageDecl { c.package_decl(node) }
		ast.Return { c.return_stmt(mut node) }
		ast.StructDecl { c.struct_decl(node) }
	}
}

fn (mut c Checker) expr(mut node ast.Expr) ast.Type {
	match mut node {
		ast.EmptyExpr { panic('found empty expr') }
		ast.BoolLiteral { return ast.bool_type }
		ast.CallExpr { return c.call_expr(mut node) }
		ast.Ident { return c.ident(node) }
		ast.IfExpr { return c.if_expr(mut node) }
		ast.InfixExpr { return c.infix_expr(mut node) }
		ast.IntegerLiteral { return ast.i32_type }
		ast.PrefixExpr { return c.prefix_expr(mut node) }
		ast.SelectorExpr { return c.selector_expr(mut node) }
		ast.StringLiteral { return ast.string_type }
	}
	return ast.void_type
}

fn (mut c Checker) assign_stmt(mut node ast.AsssignStmt) {
	is_decl := node.op == .decl_assign
	if is_decl {
		typ := c.expr(mut node.right)
		c.expr(mut node.left)
		node.right_type = typ
		node.left_type = typ
		if mut node.left is ast.Ident {
			node.left.scope.update_type(node.left.name, typ)
		}
	} else {
		c.expr(mut node.left)
		c.expr(mut node.right)
	}
}

fn (mut c Checker) const_decl(mut node ast.ConstDecl) {
	c.expr(mut node.expr)
}

fn (mut c Checker) for_stmt(mut node ast.ForStmt) {
	c.expr(mut node.cond)
	c.stmts(mut node.stmts)
}

fn (mut c Checker) for_classic_stmt(mut node ast.ForClassicStmt) {
	c.stmt(mut node.init)
	c.expr(mut node.cond)
	c.stmt(mut node.inc)
	c.stmts(mut node.stmts)
}

fn (mut c Checker) fun_decl(mut node ast.FunDecl) {
	c.stmts(mut node.stmts)
}

fn (mut c Checker) package_decl(node ast.PackageDecl) {
	c.pkg_name = node.name
}

fn (mut c Checker) return_stmt(mut node ast.Return) {
	c.expr(mut node.expr)
}

fn (mut c Checker) struct_decl(node ast.StructDecl) {
}

fn (mut c Checker) call_expr(mut node ast.CallExpr) ast.Type {
	mut found := false
	if !node.name.contains('.') && node.pkg != 'builtin' {
		full_name := '${node.pkg}.$node.name'
		if full_name in c.table.fns {
			found = true
			node.name = full_name
		}
	}
	if !found && (node.name in c.table.fns || node.lang == .c) {
		found = true
	}
	if !found {
		c.error('unknown function: $node.name')
	}
	node.return_type = c.table.fns[node.name].return_type
	if node.is_method {
		node.receiver_type = c.expr(mut node.receiver)
	}
	c.call_args(mut node.args)
	return node.return_type
}

fn (mut c Checker) call_args(mut args []ast.CallArg) {
	for mut a in args {
		c.expr(mut a.expr)
	}
}

fn (mut c Checker) ident(node ast.Ident) ast.Type {
	obj := node.scope.find(node.name)
	if obj.name.len > 0 {
		return obj.typ
	}
	return ast.void_type
}

fn (mut c Checker) if_expr(mut node ast.IfExpr) ast.Type {
	for mut b in node.branches {
		c.expr(mut b.cond)
		c.stmts(mut b.stmts)
	}
	return ast.void_type
}

fn (mut c Checker) infix_expr(mut node ast.InfixExpr) ast.Type {
	node.left_type = c.expr(mut node.left)
	node.right_type = c.expr(mut node.right)
	return node.left_type
}

fn (mut c Checker) prefix_expr(mut node ast.PrefixExpr) ast.Type {
	node.right_type = c.expr(mut node.right)
	return node.right_type
}

fn (mut c Checker) selector_expr(mut node ast.SelectorExpr) ast.Type {
	typ := c.expr(mut node.expr)
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
