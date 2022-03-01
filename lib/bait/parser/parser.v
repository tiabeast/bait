module parser

import lib.bait.token
import lib.bait.ast

struct Parser {
	all_tokens []token.Token
	path       string
mut:
	table    &ast.Table
	scope    &ast.Scope
	pkg_name string
	tidx     int
	prev_tok token.Token
	tok      token.Token
	peek_tok token.Token
}

pub fn parse_tokens(tokens []token.Token, path string, table &ast.Table) &ast.File {
	mut p := Parser{
		table: table
		path: path
		all_tokens: tokens
		scope: &ast.Scope{}
	}
	return p.parse()
}

fn (mut p Parser) parse() &ast.File {
	p.next()
	p.next()
	mut stmts := []ast.Stmt{}
	pkg_decl := p.package_decl()
	stmts << pkg_decl
	for {
		if p.tok.kind == .eof {
			break
		}
		stmts << p.top_level_stmt()
	}
	return &ast.File{
		path: p.path
		pkg: pkg_decl
		stmts: stmts
	}
}

fn (mut p Parser) open_scope() {
	p.scope = &ast.Scope{
		parent: p.scope
	}
}

fn (mut p Parser) close_scope() {
	p.scope.parent.children << p.scope
	p.scope = p.scope.parent
}

fn (mut p Parser) parse_block_no_scope() []ast.Stmt {
	p.check(.lcur)
	mut stmts := []ast.Stmt{}
	for p.tok.kind !in [.eof, .rcur] {
		stmts << p.stmt()
	}
	p.check(.rcur)
	return stmts
}

pub fn (mut p Parser) check(expected token.Kind) {
	if p.tok.kind == expected {
		p.next()
	} else {
		p.error('unexpected $p.tok, expecting $expected')
	}
}

pub fn (mut p Parser) check_name() string {
	p.check(.name)
	return p.prev_tok.lit
}

fn (p Parser) prepend_pkg(val string) string {
	if p.pkg_name == 'builtin' {
		return val
	}
	return '${p.pkg_name}.$val'
}

fn (mut p Parser) next() {
	p.prev_tok = p.tok
	p.tok = p.peek_tok
	p.peek_tok = p.all_tokens[p.tidx] or { p.all_tokens.last() }
	p.tidx++
}

fn (mut p Parser) error(msg string) {
	eprintln('$p.path: $msg')
	exit(1)
}
