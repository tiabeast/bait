// This file is part of: bait.
// Copyright (c) 2022 Lukas Neubert.
// Use of this code is governed by an MIT License (see LICENSE.md).
module parser

import lib.bait.ast
import lib.bait.token

struct Parser {
	all_tokens []token.Token
	path       string
mut:
	table    &ast.Table
	scope    &ast.Scope
	tidx     int
	prev_tok token.Token
	tok      token.Token
	peek_tok token.Token
}

pub fn parse_tokens(tokens []token.Token, path string, table &ast.Table) ast.File {
	mut p := Parser{
		path: path
		all_tokens: tokens
		table: table
		scope: &ast.Scope{
			parent: 0
		}
	}
	return p.parse()
}

fn (mut p Parser) parse() ast.File {
	p.next()
	p.next()
	mut stmts := []ast.Stmt{}
	for {
		if p.tok.kind == .eof {
			break
		}
		stmts << p.top_level_stmt()
	}
	return ast.File{
		path: p.path
		stmts: stmts
	}
}

fn (mut p Parser) open_scope() {
	p.scope = &ast.Scope{
		parent: p.scope
	}
}

fn (mut p Parser) close_scope() {
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

fn (mut p Parser) check(expected token.Kind) {
	if p.tok.kind == expected {
		p.next()
	} else {
		p.error('unexpected $p.tok, expecting $expected')
	}
}

fn (mut p Parser) check_name() string {
	p.check(.name)
	return p.prev_tok.lit
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
