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
		ast.AssignStmt { c.assign_stmt(mut node) }
		ast.ConstDecl { c.const_decl(mut node) }
		ast.ExprStmt { c.expr(mut node.expr) }
		ast.ForLoop { c.for_stmt(mut node) }
		ast.ForClassicLoop { c.for_classic_stmt(mut node) }
		ast.FunDecl { c.fun_decl(mut node) }
		ast.PackageDecl { c.package_decl(node) }
		ast.Return { c.return_stmt(mut node) }
		ast.StructDecl { c.struct_decl(node) }
	}
}

fn (mut c Checker) expr(mut node ast.Expr) ast.Type {
	match mut node {
		ast.EmptyExpr { panic('found empty expr') }
		ast.ArrayInit { return c.array_init(mut node) }
		ast.BoolLiteral { return ast.bool_type }
		ast.CallExpr { return c.call_expr(mut node) }
		ast.CastExpr { return c.cast_expr(mut node) }
		ast.CharLiteral { return ast.byte_type }
		ast.Ident { return c.ident(mut node) }
		ast.IfExpr { return c.if_expr(mut node) }
		ast.IndexExpr { return c.index_expr(mut node) }
		ast.InfixExpr { return c.infix_expr(mut node) }
		ast.IntegerLiteral { return ast.i32_type }
		ast.PrefixExpr { return c.prefix_expr(mut node) }
		ast.SelectorExpr { return c.selector_expr(mut node) }
		ast.StringLiteral { return ast.string_type }
		ast.StructInit { return c.struct_init(mut node) }
	}
	return ast.void_type
}

fn (mut c Checker) assign_stmt(mut node ast.AssignStmt) {
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
	typ := c.expr(mut node.expr)
	c.table.global_scope.update_type(node.name, typ)
}

fn (mut c Checker) for_stmt(mut node ast.ForLoop) {
	c.expr(mut node.cond)
	c.stmts(mut node.stmts)
}

fn (mut c Checker) for_classic_stmt(mut node ast.ForClassicLoop) {
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
	if node.expr !is ast.EmptyExpr {
		c.expr(mut node.expr)
	}
}

fn (mut c Checker) struct_decl(node ast.StructDecl) {
}

fn (mut c Checker) array_init(mut node ast.ArrayInit) ast.Type {
	if node.len_expr !is ast.EmptyExpr {
		c.expr(mut node.len_expr)
	}
	for mut e in node.exprs {
		c.expr(mut e)
	}
	return node.arr_type
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
		rec_sym := c.table.get_type_symbol(node.receiver_type)
		return_sym := c.table.get_type_symbol(node.return_type)
		if rec_sym.kind == .array && return_sym.name == 'array' {
			node.return_type = node.receiver_type
		}
	}
	c.call_args(mut node.args)
	return node.return_type
}

fn (mut c Checker) call_args(mut args []ast.CallArg) {
	for mut a in args {
		c.expr(mut a.expr)
	}
}

fn (mut c Checker) cast_expr(mut node ast.CastExpr) ast.Type {
	c.expr(mut node.expr)
	return node.target_type
}

fn (mut c Checker) ident(mut node ast.Ident) ast.Type {
	obj := node.scope.find(node.name)
	if obj.name.len > 0 {
		node.kind = .variable
		return obj.typ
	}
	gobj := c.table.global_scope.find(node.name)
	if gobj.name.len > 0 {
		node.kind = .constant
		return gobj.typ
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

fn (mut c Checker) index_expr(mut node ast.IndexExpr) ast.Type {
	node.left_type = c.expr(mut node.left)
	c.expr(mut node.index)
	sym := c.table.get_type_symbol(node.left_type)
	if sym.kind == .array {
		return (sym.info as ast.ArrayInfo).elem_type
	}
	if sym.kind == .string {
		return ast.byte_type
	}
	return node.left_type
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
	node.expr_type = c.expr(mut node.expr)
	fsym := c.table.get_type_symbol(node.expr_type)
	match fsym.info {
		ast.ArrayInfo {
			if node.field_name == 'len' {
				return ast.i32_type
			}
		}
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

fn (mut c Checker) struct_init(mut node ast.StructInit) ast.Type {
	for mut f in node.fields {
		f.typ = c.expr(mut f.expr)
	}
	return node.typ
}

fn (mut c Checker) error(msg string) {
	c.errors << msg
}
