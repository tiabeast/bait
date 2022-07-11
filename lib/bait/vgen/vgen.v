// This file is part of: bait.
// Copyright (c) 2022 Lukas Neubert.
// Use of this code is governed by an MIT License (see LICENSE.md).
module vgen

import strings
import lib.bait.ast

struct Gen {
	table &ast.Table
mut:
	inside_for_classic bool
	indent             int
	empty_line         bool
	out                strings.Builder
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
		ast.ForClassicLoop { g.for_classic_loop(node) }
		ast.FunDecl { g.fun_decl(node) }
	}
	if node is ast.ExprStmt && !g.empty_line {
		g.writeln('')
	}
}

fn (mut g Gen) expr(node ast.Expr) {
	match node {
		ast.EmptyExpr { panic('found empty expr') }
		ast.BoolLiteral { g.bool_literal(node) }
		ast.CallExpr { g.call_expr(node) }
		ast.FloatLiteral { g.float_literal(node) }
		ast.Ident { g.ident(node) }
		ast.IfExpr { g.if_expr(node) }
		ast.InfixExpr { g.infix_expr(node) }
		ast.IntegerLiteral { g.integer_literal(node) }
		ast.StringLiteral { g.string_literal(node) }
	}
}

fn (mut g Gen) assign_stmt(node ast.AssignStmt) {
	g.expr(node.left)
	g.write(' $node.op.vstr() ')
	g.expr(node.right)
	if !g.inside_for_classic {
		g.writeln('')
	}
}

fn (mut g Gen) for_classic_loop(node ast.ForClassicLoop) {
	g.inside_for_classic = true
	g.write('for ')
	g.stmt(node.init)
	g.write('; ')
	g.expr(node.cond)
	g.write('; ')
	g.stmt(node.inc)
	g.writeln(' {')
	g.inside_for_classic = true
	g.stmts(node.stmts)
	g.writeln('}')
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

fn (mut g Gen) bool_literal(node ast.BoolLiteral) {
	g.write('$node.val')
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

fn (mut g Gen) float_literal(node ast.FloatLiteral) {
	g.write(node.val)
}

fn (mut g Gen) ident(node ast.Ident) {
	name := v_name(node.name)
	g.write(name)
}

fn (mut g Gen) if_expr(node ast.IfExpr) {
	for i, b in node.branches {
		if i > 0 {
			g.write('} else ')
		}
		if node.has_else && i == node.branches.len - 1 {
			g.writeln('{')
		} else {
			g.write('if ')
			g.expr(b.cond)
			g.writeln(' {')
		}
		g.stmts(b.stmts)
	}
	g.writeln('}')
}

fn (mut g Gen) infix_expr(node ast.InfixExpr) {
	g.expr(node.left)
	g.write(' $node.op.vstr() ')
	g.expr(node.right)
}

fn (mut g Gen) integer_literal(node ast.IntegerLiteral) {
	g.write(node.val)
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
