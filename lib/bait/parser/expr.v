module parser

import lib.bait.ast

fn (mut p Parser) expr(precedence int) ast.Expr {
	mut node := ast.empty_expr()
	match p.tok.kind {
		.amp {
			node = p.cast_expr(true)
		}
		.char {
			node = p.char_literal()
		}
		.lbr {
			node = p.array_init()
		}
		.minus {
			if p.peek_tok.kind == .number {
				node = p.integer_literal()
			} else {
				node = p.prefix_expr()
			}
		}
		.name {
			node = p.name_expr()
		}
		.number {
			node = p.integer_literal()
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

fn (mut p Parser) expr_with_left(left_ ast.Expr, precedence int) ast.Expr {
	mut left := left_
	for precedence < p.tok.precedence() {
		if p.tok.kind == .dot {
			left = p.dot_expr(left)
		} else if p.tok.kind in [.plus, .minus, .mul, .div, .mod, .eq, .lt, .gt, .le, .ge] {
			return p.infix_expr(left)
		} else if p.tok.kind == .lbr {
			return p.index_expr(left)
		} else {
			return left
		}
	}
	return left
}

fn (mut p Parser) array_init() ast.ArrayInit {
	mut exprs := []ast.Expr{}
	mut elem_type := ast.void_type
	mut arr_type := ast.void_type
	mut len_expr := ast.empty_expr()
	p.check(.lbr)
	if p.tok.kind == .rbr {
		p.next()
		if p.tok.kind == .name {
			elem_type = p.parse_type()
			idx := p.table.find_or_register_array(elem_type)
			arr_type = ast.new_type(idx)
		}
		if p.tok.kind == .lcur {
			p.next()
			for p.tok.kind != .rcur {
				key := p.check_name()
				p.check(.colon)
				if key == 'len' {
					len_expr = p.expr(0)
				}
			}
			p.check(.rcur)
		}
	} else {
		for p.tok.kind !in [.rbr, .eof] {
			exprs << p.expr(0)
			if p.tok.kind == .comma {
				p.next()
			}
		}
		p.check(.rbr)
	}
	return ast.ArrayInit{
		exprs: exprs
		arr_type: arr_type
		elem_type: elem_type
		len_expr: len_expr
	}
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

fn (mut p Parser) cast_expr(has_amp bool) ast.CastExpr {
	mut target_type := p.parse_type()
	if has_amp {
		target_type.set_nr_amp(1)
	}
	p.check(.lpar)
	expr := p.expr(0)
	p.check(.rpar)
	return ast.CastExpr{
		target_type: target_type
		expr: expr
	}
}

fn (mut p Parser) char_literal() ast.CharLiteral {
	p.next()
	return ast.CharLiteral{
		val: p.prev_tok.lit
	}
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

fn (mut p Parser) index_expr(left ast.Expr) ast.IndexExpr {
	p.check(.lbr)
	index := p.expr(0)
	p.check(.rbr)
	return ast.IndexExpr{
		left: left
		index: index
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
		if p.tok.lit in p.table.type_idxs {
			return p.cast_expr(false)
		}
		return p.call_expr(lang)
	} else if p.peek_tok.kind == .lcur && !p.inside_for {
		return p.struct_init()
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

fn (mut p Parser) struct_init() ast.StructInit {
	typ := p.parse_type()
	p.check(.lcur)
	mut fields := []ast.StructInitField{}
	for p.tok.kind != .rcur {
		name := p.check_name()
		p.check(.colon)
		expr := p.expr(0)
		fields << ast.StructInitField{
			name: name
			expr: expr
		}
	}
	p.check(.rcur)
	return ast.StructInit{
		typ: typ
		fields: fields
	}
}
