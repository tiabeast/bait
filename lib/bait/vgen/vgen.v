// This file is part of: bait.
// Copyright (c) 2022 Lukas Neubert.
// Use of this code is governed by an MIT License (see LICENSE.md).
module vgen

import strings
import lib.bait.ast

struct Gen {
	table &ast.Table
mut:
	indent     int
	empty_line bool
	out        strings.Builder
}

pub fn gen(files []ast.File, table &ast.Table) string {
	mut g := Gen{
		table: table
		out: strings.new_builder(10000)
	}
	for file in files {
		g.indent--
		g.stmts(file.stmts)
		g.indent++
	}
	mut sb := strings.new_builder(100000)
	sb.writeln(g.out.str())
	return sb.str()
}

fn (mut g Gen) stmts(stmts []ast.Stmt) {
	g.indent++
	for stmt in stmts {
		g.stmt(stmt)
	}
	g.indent--
}

fn (mut g Gen) stmt(node ast.Stmt) {
	match node {
		ast.EmptyStmt { panic('found empty stmt') }
		ast.AssignStmt { g.assign_stmt(node) }
		ast.ExprStmt { g.expr(node.expr) }
		ast.FunDecl { g.fun_decl(node) }
	}
	if node is ast.ExprStmt && !g.empty_line {
		g.writeln('')
	}
}

fn (mut g Gen) expr(node ast.Expr) {
	match node {
		ast.EmptyExpr { panic('found empty expr') }
		ast.CallExpr { g.call_expr(node) }
		ast.Ident { g.ident(node) }
		ast.StringLiteral { g.string_literal(node) }
	}
}

fn (mut g Gen) assign_stmt(node ast.AssignStmt) {
	g.expr(node.left)
	if node.op == .decl_assign {
		g.write(' := ')
	}
	g.expr(node.right)
	g.writeln('')
}

fn (mut g Gen) fun_decl(node ast.FunDecl) {
	name := v_name(node.name)
	g.write('fn ${name}(')
	g.fun_params(node.params)
	type_name := g.typ(node.return_type)
	g.writeln(')$type_name {')
	g.stmts(node.stmts)
	g.writeln('}\n')
}

fn (mut g Gen) fun_params(params []ast.Param) {
	for i, p in params {
		name := v_name(p.name)
		arg_type := g.typ(p.typ)
		g.write('$name $arg_type')
		if i < params.len - 1 {
			g.write(', ')
		}
	}
}

fn (mut g Gen) call_expr(node ast.CallExpr) {
	name := v_name(node.name)
	g.write('${name}(')
	g.call_args(node.args)
	g.write(')')
}

fn (mut g Gen) call_args(args []ast.Expr) {
	for i, expr in args {
		g.expr(expr)
		if i < args.len - 1 {
			g.write(', ')
		}
	}
}

fn (mut g Gen) ident(node ast.Ident) {
	name := v_name(node.name)
	g.write(name)
}

fn (mut g Gen) string_literal(node ast.StringLiteral) {
	g.write("'$node.val'")
}

fn (mut g Gen) typ(typ ast.Type) string {
	if typ == ast.void_type {
		return ''
	}
	sym := g.table.get_type_symbol(typ)
	vname := v_name(sym.name)
	return '$vname'
}

fn (mut g Gen) write(s string) {
	if g.indent > 0 && g.empty_line {
		g.out.write_string(strings.repeat(`\t`, g.indent))
	}
	g.out.write_string(s)
	g.empty_line = false
}

fn (mut g Gen) writeln(s string) {
	if g.indent > 0 && g.empty_line {
		g.out.write_string(strings.repeat(`\t`, g.indent))
	}
	g.out.writeln(s)
	g.empty_line = true
}

const v_reserved = []string{}

fn v_name(name string) string {
	if name in vgen.v_reserved {
		return 'bait_$name'
	}
	return name
}
