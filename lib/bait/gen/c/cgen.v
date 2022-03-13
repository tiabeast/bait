module c

import strings
import lib.bait.ast

const c_reserved = ['main']

const builtin_struct_types = ['string']

struct Gen {
	table &ast.Table
mut:
	pkg_name   string
	lang       ast.Language = .bait
	indent     int
	empty_line bool
	cheaders   strings.Builder
	type_defs  strings.Builder
	type_impls strings.Builder
	fun_decls  strings.Builder
	out        strings.Builder
}

pub fn gen(files []&ast.File, table &ast.Table) string {
	mut g := Gen{
		table: table
		cheaders: strings.new_builder(1000)
		type_defs: strings.new_builder(1000)
		type_impls: strings.new_builder(1000)
		fun_decls: strings.new_builder(1000)
		out: strings.new_builder(10000)
	}
	g.init()
	for file in files {
		g.indent--
		g.stmts(file.stmts)
		g.indent++
	}
	g.c_main()
	mut sb := strings.new_builder(100000)
	sb.writeln(g.cheaders.str())
	sb.writeln(g.type_defs.str())
	sb.writeln(g.type_impls.str())
	sb.writeln(g.fun_decls.str())
	sb.writeln(g.out.str())
	return sb.str()
}

fn (mut g Gen) init() {
	g.cheaders.writeln(c_includes)
	g.cheaders.writeln(c_builtin_types)
	g.cheaders.writeln(c_helpers)
	mut builtin_struct_syms := []ast.TypeSymbol{}
	for bst in c.builtin_struct_types {
		builtin_struct_syms << g.table.type_symbols[g.table.type_idxs[bst]]
	}
	g.write_types(builtin_struct_syms)
}

fn (mut g Gen) write_types(type_syms []ast.TypeSymbol) {
	for tsym in type_syms {
		match tsym.info {
			ast.StructInfo {
				g.type_defs.writeln('typedef struct $tsym.name $tsym.name;')
				g.type_impls.writeln('struct $tsym.name {')
				for field in tsym.info.fields {
					type_name := g.typ(field.typ)
					field_name := c_name(field.name)
					g.type_impls.writeln('\t$type_name $field_name;')
				}
				g.type_impls.writeln('};\n')
			}
			ast.OtherInfo {}
		}
	}
}

fn (mut g Gen) c_main() {
	g.writeln('int main(int argc, char* argv[]) {')
	g.writeln('\tmain__main();')
	g.writeln('\treturn 0;')
	g.writeln('}')
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
		ast.EmptyStmt {}
		ast.AsssignStmt { g.assign_stmt(node) }
		ast.ConstDecl { g.const_decl(node) }
		ast.ExprStmt { g.expr(node.expr) }
		ast.FunDecl { g.fun_decl(node) }
		ast.PackageDecl { g.package_decl(node) }
		ast.Return { g.return_stmt(node) }
		ast.StructDecl {} // struct declarations are handled by write_types
	}
	if node is ast.ExprStmt && !g.empty_line {
		g.writeln(';')
	}
}

fn (mut g Gen) expr(node ast.Expr) {
	match node {
		ast.EmptyExpr {}
		ast.CallExpr { g.call_expr(node) }
		ast.Ident { g.ident(node) }
		ast.IntegerLiteral { g.integer_literal(node) }
		ast.SelectorExpr { g.selector_expr(node) }
		ast.StringLiteral { g.string_literal(node) }
	}
}

fn (mut g Gen) expr_string(node ast.Expr) string {
	pos := g.out.len
	g.expr(node)
	expr_str := g.out.cut_to(pos)
	return expr_str.trim_space()
}

fn (mut g Gen) assign_stmt(node ast.AsssignStmt) {
	is_decl := node.op == .decl_assign
	if is_decl {
		typ := g.typ(node.right_type)
		g.write('$typ ')
	}
	g.expr(node.left)
	g.write(' = ')
	g.expr(node.right)
	g.writeln(';')
}

fn (mut g Gen) const_decl(node ast.ConstDecl) {
	name := c_name(node.name).to_upper()
	val := g.expr_string(node.expr)
	g.type_impls.writeln('#define CONST_$name $val')
}

fn (mut g Gen) fun_decl(node ast.FunDecl) {
	mut name := c_name(node.name)
	if node.is_method {
		sym := g.table.get_type_symbol(node.params[0].typ)
		name = '${sym.name}_$name'
	}
	type_name := g.typ(node.return_type)
	s := '$type_name ${name}('
	g.fun_decls.write_string(s)
	g.write(s)
	g.fun_params(node.params)
	g.fun_decls.writeln(');')
	g.writeln(') {')
	g.stmts(node.stmts)
	g.writeln('};\n')
}

fn (mut g Gen) fun_params(params []ast.Param) {
	for i, p in params {
		name := c_name(p.name)
		arg_type := g.typ(p.typ)
		s := '$arg_type $name'
		g.fun_decls.write_string(s)
		g.write(s)
		if i < params.len - 1 {
			g.fun_decls.write_string(', ')
			g.write(', ')
		}
	}
}

fn (mut g Gen) package_decl(node ast.PackageDecl) {
	g.pkg_name = node.name
}

fn (mut g Gen) return_stmt(node ast.Return) {
	g.write('return ')
	if node.expr.is_auto_deref() {
		g.write('*')
	}
	g.expr(node.expr)
	g.writeln(';')
}

fn (mut g Gen) call_expr(node ast.CallExpr) {
	g.lang = node.lang
	mut name := c_name(node.name)
	if node.is_method {
		sym := g.table.get_type_symbol(node.receiver_type)
		name = '${sym.name}_$name'
	}
	g.write('${name}(')
	if node.is_method {
		if node.receiver_type.nr_amps() == 0 {
			g.write('&')
		}
		g.expr(node.receiver)
		if node.args.len > 0 {
			g.write(', ')
		}
	}
	g.call_args(node.args)
	g.write(')')
	g.lang = .bait
}

fn (mut g Gen) call_args(args []ast.CallArg) {
	for i, arg in args {
		g.expr(arg.expr)
		if i < args.len - 1 {
			g.write(', ')
		}
	}
}

fn (mut g Gen) ident(node ast.Ident) {
	name := c_name(node.name)
	g.write(name)
}

fn (mut g Gen) integer_literal(node ast.IntegerLiteral) {
	g.write(node.val)
}

fn (mut g Gen) selector_expr(node ast.SelectorExpr) {
	g.expr(node.expr)
	g.write('.')
	g.write(node.field_name)
}

fn (mut g Gen) string_literal(node ast.StringLiteral) {
	if g.lang == .c {
		g.write('"$node.val"')
	} else {
		g.write('SLIT("$node.val")')
	}
}

fn (mut g Gen) typ(typ ast.Type) string {
	sym := g.table.get_type_symbol(typ)
	muls := '*'.repeat(typ.nr_amps())
	return '$sym.name$muls'
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

fn c_name(n string) string {
	name := n.replace('.', '__')
	if name in c.c_reserved {
		return 'bait_$name'
	}
	return name
}

fn no_dots(n string) string {
	return n.replace('.', '__')
}
