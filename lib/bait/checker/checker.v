// This file is part of: bait.
// Copyright (c) 2022 Lukas Neubert.
// Use of this code is governed by an MIT License (see LICENSE.md).
module checker

import lib.bait.ast

pub struct Checker {
pub mut:
	errors []string
mut:
	table    &ast.Table
	pkg_name string
}

pub fn new_checker(table &ast.Table) Checker {
	return Checker{
		table: table
	}
}

pub fn (mut c Checker) check_files(files []&ast.File) {
	for f in files {
		c.check(f)
	}
}

fn (mut c Checker) check(file ast.File) {
	mut mfile := unsafe { file }
	c.stmts(mut mfile.stmts)
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
		ast.ExprStmt { c.expr(mut node.expr) }
		ast.ForClassicLoop { c.for_classic_stmt(mut node) }
		ast.FunDecl { c.fun_decl(mut node) }
		ast.PackageDecl { c.package_decl(node) }
	}
}

fn (mut c Checker) expr(mut node ast.Expr) ast.Type {
	match mut node {
		ast.EmptyExpr { panic('found empty expr') }
		ast.BoolLiteral { return ast.bool_type }
		ast.CallExpr { return c.call_expr(mut node) }
		ast.FloatLiteral { return ast.f64_type }
		ast.Ident { return c.ident(node) }
		ast.IfExpr { return c.if_expr(mut node) }
		ast.InfixExpr { return c.infix_expr(mut node) }
		ast.IntegerLiteral { return ast.i32_type }
		ast.StringLiteral { return ast.string_type }
	}
	return ast.void_type
}

fn (mut c Checker) assign_stmt(mut node ast.AssignStmt) {
	c.expr(mut node.right)
	c.expr(mut node.left)
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
	if node.name in c.table.funs {
		found = true
	}
	if !found && !node.name.contains('.') {
		if node.pkg_name.len == 0 {
			node.pkg_name = 'builtin'
		}
		full_name := '${node.pkg_name}.$node.name'
		if full_name in c.table.funs {
			found = true
			node.name = full_name
		}
	}
	if !found {
		c.error('unknown function: $node.name')
	}
}

fn (mut c Checker) method_call(mut node ast.CallExpr) {
	c.expr(mut node.left)
}

fn (mut c Checker) call_args(mut args []ast.Expr) {
	for mut expr in args {
		c.expr(mut expr)
	}
}

fn (mut c Checker) ident(node ast.Ident) ast.Type {
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
	c.expr(mut node.left)
	c.expr(mut node.right)
	return ast.void_type
}

fn (mut c Checker) error(msg string) {
	c.errors << msg
}
