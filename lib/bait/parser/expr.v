module parser

import lib.bait.ast

fn (mut p Parser) expr(precedence int) ast.Expr {
	mut node := ast.empty_expr()
	match p.tok.kind {
		.minus {
			if p.peek_tok.kind == .number {
				node = p.integer_literal()
			} else {
				node = p.prefix_expr()
			}
		}
		.number {
			node = p.integer_literal()
		}
		.name {
			node = p.name_expr()
		}
		.string {
			node = p.string_literal()
		}
		.key_if {
			node = p.if_expr()
		}
		.key_true, .key_false {
			node = p.bool_literal()
		}
		else {
			p.error('invalid expression: $p.tok')
		}
	}
	return p.expr_with_left(node, precedence)
}

fn (mut p Parser) expr_with_left(left ast.Expr, precedence int) ast.Expr {
	mut node := left
	for precedence < p.tok.precedence() {
		if p.tok.kind == .dot {
			node = p.dot_expr(node)
		} else if p.tok.kind in [.plus, .minus, .mul, .div, .mod, .eq, .lt, .gt, .le, .ge] {
			return p.infix_expr(node)
		} else {
			return node
		}
	}
	return node
}

fn (mut p Parser) bool_literal() ast.BoolLiteral {
	p.next()
	return ast.BoolLiteral{
		val: p.prev_tok.kind == .key_true
	}
}

fn (mut p Parser) call_expr(lang ast.Language) ast.CallExpr {
	name := p.check_name()
	p.check(.lpar)
	args := p.call_args()
	p.check(.rpar)
	return ast.CallExpr{
		name: name
		pkg: p.pkg_name
		args: args
		lang: lang
	}
}

fn (mut p Parser) call_args() []ast.CallArg {
	mut args := []ast.CallArg{}
	for p.tok.kind != .rpar {
		expr := p.expr(0)
		args << ast.CallArg{
			expr: expr
		}
		if p.tok.kind != .rpar {
			p.check(.comma)
		}
	}
	return args
}

fn (mut p Parser) dot_expr(left ast.Expr) ast.Expr {
	p.check(.dot)
	name := p.check_name()
	if p.tok.kind == .lpar {
		p.check(.lpar)
		args := p.call_args()
		p.check(.rpar)
		return ast.CallExpr{
			name: name
			args: args
			receiver: left
			is_method: true
		}
	}
	return ast.SelectorExpr{
		expr: left
		field_name: name
	}
}

fn (mut p Parser) ident() ast.Ident {
	name := p.check_name()
	return ast.Ident{
		name: name
		scope: p.scope
	}
}

fn (mut p Parser) if_expr() ast.IfExpr {
	mut branches := []ast.IfBranch{}
	for {
		p.check(.key_if)
		cond := p.expr(0)
		stmts := p.parse_block_no_scope()
		branches << ast.IfBranch{
			cond: cond
			stmts: stmts
		}
		break
	}
	return ast.IfExpr{
		branches: branches
	}
}

fn (mut p Parser) infix_expr(left ast.Expr) ast.InfixExpr {
	op := p.tok.kind
	p.next()
	right := p.expr(0)
	return ast.InfixExpr{
		left: left
		right: right
		op: op
	}
}

fn (mut p Parser) integer_literal() ast.IntegerLiteral {
	is_neg := p.tok.kind == .minus
	if is_neg {
		p.next()
	}
	mut val := p.tok.lit
	if is_neg {
		val = '-$val'
	}
	p.next()
	return ast.IntegerLiteral{
		val: val
	}
}

fn (mut p Parser) name_expr() ast.Expr {
	mut lang := ast.Language.bait
	if p.tok.lit == 'C' {
		lang = .c
		p.next()
		p.check(.dot)
	}
	if p.peek_tok.kind == .lpar {
		return p.call_expr(lang)
	}
	return p.ident()
}

fn (mut p Parser) prefix_expr() ast.PrefixExpr {
	op := p.tok.kind
	p.next()
	right := p.name_expr()
	return ast.PrefixExpr{
		op: op
		right: right
	}
}

fn (mut p Parser) string_literal() ast.StringLiteral {
	val := p.tok.lit
	p.next()
	return ast.StringLiteral{
		val: val
	}
}
