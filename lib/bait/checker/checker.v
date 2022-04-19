// This file is part of: bait.
// Copyright (c) 2022 Lukas Neubert.
// Use of this code is governed by an MIT License (see LICENSE.md).
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
		ast.AssertStmt { c.assert_stmt(mut node) }
		ast.AssignStmt { c.assign_stmt(mut node) }
		ast.ConstDecl { c.const_decl(mut node) }
		ast.ExprStmt { c.expr(mut node.expr) }
		ast.ForLoop { c.for_stmt(mut node) }
		ast.ForClassicLoop { c.for_classic_stmt(mut node) }
		ast.FunDecl { c.fun_decl(mut node) }
		ast.GlobalDecl { c.global_decl(mut node) }
		ast.Import { c.import_stmt(node) }
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
		ast.CharLiteral { return ast.u8_type }
		ast.Ident { return c.ident(mut node) }
		ast.IfExpr { return c.if_expr(mut node) }
		ast.IndexExpr { return c.index_expr(mut node) }
		ast.InfixExpr { return c.infix_expr(mut node) }
		ast.IntegerLiteral { return ast.i32_type }
		ast.MapInit { return c.map_init(mut node) }
		ast.PrefixExpr { return c.prefix_expr(mut node) }
		ast.SelectorExpr { return c.selector_expr(mut node) }
		ast.StringLiteral { return ast.string_type }
		ast.StructInit { return c.struct_init(mut node) }
	}
	return ast.void_type
}

fn (mut c Checker) assert_stmt(mut node ast.AssertStmt) {
	c.expr(mut node.expr)
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
	node.typ = typ
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

fn (mut c Checker) global_decl(mut node ast.GlobalDecl) {
	c.expr(mut node.expr)
}

fn (mut c Checker) import_stmt(node ast.Import) {
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
	if node.exprs.len > 0 && node.elem_type == ast.void_type {
		for i, mut e in node.exprs {
			typ := c.expr(mut e)
			if i == 0 {
				node.elem_type = typ
			}
		}
		idx := c.table.find_or_register_array(node.elem_type)
		node.arr_type = ast.new_type(idx)
	}
	return node.arr_type
}

fn (mut c Checker) call_expr(mut node ast.CallExpr) ast.Type {
	if node.is_method {
		c.method_call(mut node)
	} else {
		c.fun_call(mut node)
	}
	c.call_args(mut node.args)
	return node.return_type
}

fn (mut c Checker) fun_call(mut node ast.CallExpr) {
	mut found := false
	if node.name in c.table.fns || node.lang == .c {
		found = true
	}
	if !found && !node.name.contains('.') && node.pkg != 'builtin' {
		full_name := '${node.pkg}.$node.name'
		if full_name in c.table.fns {
			found = true
			node.name = full_name
		}
	}
	if !found {
		c.error('unknown function: $node.name')
	}
	node.return_type = c.table.fns[node.name].return_type
}

fn (mut c Checker) method_call(mut node ast.CallExpr) {
	node.receiver_type = c.expr(mut node.receiver)
	rec_sym := c.table.get_type_symbol(node.receiver_type)
	if m := c.table.get_method(rec_sym, node.name) {
		node.return_type = m.return_type
	} else {
		c.error('unknown method: ${rec_sym.name}.$node.name')
	}
	return_sym := c.table.get_type_symbol(node.return_type)
	if rec_sym.kind == .array && return_sym.name == 'array' {
		node.return_type = node.receiver_type
	}
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
	if node.lang != .bait {
		return ast.void_type
	}
	obj := node.scope.find(node.name)
	if obj.name.len > 0 {
		node.kind = .variable
		return obj.typ
	}
	if !node.name.contains('.') && node.pkg != 'builtin' {
		node.name = '${node.pkg}.$node.name'
	}
	gobj := c.table.global_scope.find(node.name)
	if gobj.name.len > 0 {
		if gobj.is_global {
			node.kind = .global
		} else {
			node.kind = .constant
		}

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
	if sym.kind == .map {
		return (sym.info as ast.MapInfo).val_type
	}
	if sym.kind == .string {
		return ast.u8_type
	}
	return node.left_type
}

fn (mut c Checker) infix_expr(mut node ast.InfixExpr) ast.Type {
	node.left_type = c.expr(mut node.left)
	node.right_type = c.expr(mut node.right)
	return node.left_type
}

fn (mut c Checker) map_init(mut node ast.MapInit) ast.Type {
	info := c.table.get_type_symbol(node.typ).info as ast.MapInfo
	node.key_type = info.key_type
	node.val_type = info.val_type
	return node.typ
}

fn (mut c Checker) prefix_expr(mut node ast.PrefixExpr) ast.Type {
	node.right_type = c.expr(mut node.right)
	return node.right_type
}

fn (mut c Checker) selector_expr(mut node ast.SelectorExpr) ast.Type {
	if mut node.expr is ast.IndexExpr {
		node.expr.is_selector = true
	}
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
		ast.MapInfo {}
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
