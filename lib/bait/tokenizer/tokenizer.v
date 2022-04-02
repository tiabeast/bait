// This file is part of: bait programming language
// Copyright (c) 2022 Lukas Neubert
// Use of this code is governed by an MIT License (see LICENSE.md).
module tokenizer

import os
import lib.bait.token

struct Tokenizer {
	text string
mut:
	pos              int = -1
	line_nr          int = 1
	is_inside_string bool
}

pub fn tokenize_file(path string) []token.Token {
	text := os.read_file(path) or { panic(err) }
	mut t := Tokenizer{
		text: text
	}
	return t.scan_all_tokens()
}

fn (mut t Tokenizer) scan_all_tokens() []token.Token {
	mut all_tokens := []token.Token{}
	for {
		tok := t.text_scan()
		all_tokens << tok
		if tok.kind == .eof {
			break
		}
	}
	return all_tokens
}

pub fn (mut t Tokenizer) text_scan() token.Token {
	for {
		t.pos++
		if !t.is_inside_string {
			t.skip_whitespace()
		}
		if t.pos >= t.text.len {
			return t.new_eof_token()
		}
		c := t.text[t.pos]
		if is_name_start_char(c) {
			name := t.ident_name()
			kind := token.keywords[name]
			if kind != .unknown {
				return t.new_token(kind, '')
			}
			return t.new_token(.name, name)
		} else if c.is_digit() {
			num := t.number_literal()
			return t.new_token(.number, num)
		}
		nextc := t.next_char()
		match c {
			`'` {
				str := t.string_literal()
				return t.new_token(.string, str)
			}
			`\`` {
				val := t.char_literal()
				return t.new_token(.char, val)
			}
			`+` {
				if nextc == `=` {
					t.pos++
					return t.new_token(.plus_assign, '')
				}
				return t.new_token(.plus, '')
			}
			`-` {
				if nextc == `=` {
					t.pos++
					return t.new_token(.minus_assign, '')
				}
				return t.new_token(.minus, '')
			}
			`*` {
				if nextc == `=` {
					t.pos++
					return t.new_token(.mul_assign, '')
				}
				return t.new_token(.mul, '')
			}
			`/` {
				if nextc == `=` {
					t.pos++
					return t.new_token(.div_assign, '')
				} else if nextc == `/` {
					t.ignore_line()
					continue
				}
				return t.new_token(.div, '')
			}
			`%` {
				if nextc == `=` {
					t.pos++
					return t.new_token(.mod_assign, '')
				}
				return t.new_token(.mod, '')
			}
			`!` {
				if nextc == `=` {
					t.pos++
					return t.new_token(.ne, '')
				}
			}
			`=` {
				if nextc == `=` {
					t.pos++
					return t.new_token(.eq, '')
				}
				return t.new_token(.assign, '')
			}
			`(` {
				return t.new_token(.lpar, '')
			}
			`)` {
				return t.new_token(.rpar, '')
			}
			`[` {
				return t.new_token(.lbr, '')
			}
			`]` {
				return t.new_token(.rbr, '')
			}
			`{` {
				return t.new_token(.lcur, '')
			}
			`}` {
				return t.new_token(.rcur, '')
			}
			`.` {
				return t.new_token(.dot, '')
			}
			`,` {
				return t.new_token(.comma, '')
			}
			`:` {
				if nextc == `=` {
					t.pos++
					return t.new_token(.decl_assign, '')
				}
				return t.new_token(.colon, '')
			}
			`;` {
				return t.new_token(.semicolon, '')
			}
			`&` {
				return t.new_token(.amp, '')
			}
			`<` {
				if nextc == `=` {
					t.pos++
					return t.new_token(.le, '')
				}
				return t.new_token(.lt, '')
			}
			`>` {
				if nextc == `=` {
					t.pos++
					return t.new_token(.ge, '')
				}
				return t.new_token(.gt, '')
			}
			else {}
		}
		t.error('invalid character: $c.ascii_str()')
	}
	return t.new_eof_token()
}

fn (mut t Tokenizer) ident_name() string {
	start := t.pos
	t.pos++
	for t.pos < t.text.len {
		c := t.text[t.pos]
		if !is_name_char(c) {
			break
		}
		t.pos++
	}
	name := t.text[start..t.pos]
	t.pos--
	return name
}

fn (mut t Tokenizer) string_literal() string {
	start_pos := t.pos + 1
	for {
		t.pos++
		if t.pos >= t.text.len {
			t.error('unfinished string literal')
		}
		c := t.text[t.pos]
		if c == `\\` {
			t.pos++
			continue
		}
		if c == `'` {
			t.is_inside_string = false
			break
		}
	}
	return t.text[start_pos..t.pos]
}

fn (mut t Tokenizer) char_literal() string {
	start_pos := t.pos + 1
	for {
		t.pos++
		if t.pos >= t.text.len {
			break
		}
		c := t.text[t.pos]
		if c == `\\` {
			t.pos++
			continue
		}
		if c == `\`` {
			break
		}
	}
	return t.text[start_pos..t.pos]
}

fn (mut t Tokenizer) number_literal() string {
	start_pos := t.pos
	for {
		if !t.text[t.pos].is_digit() {
			break
		}
		t.pos++
	}
	lit := t.text[start_pos..t.pos]
	t.pos--
	return lit
}

fn (t Tokenizer) new_token(kind token.Kind, lit string) token.Token {
	return token.Token{
		kind: kind
		lit: lit
		pos: token.Position{
			line_nr: t.line_nr
		}
	}
}

fn (t Tokenizer) new_eof_token() token.Token {
	return token.Token{
		kind: .eof
	}
}

fn (t Tokenizer) next_char() byte {
	return if t.pos + 1 < t.text.len { t.text[t.pos + 1] } else { `\0` }
}

fn (mut t Tokenizer) skip_whitespace() {
	for t.pos < t.text.len {
		c := t.text[t.pos]
		if c !in [` `, `\t`, `\n`] {
			return
		}
		if c == `\n` {
			t.line_nr++
		}
		t.pos++
	}
}

fn (mut t Tokenizer) ignore_line() {
	for t.pos < t.text.len && t.text[t.pos] != `\n` {
		t.pos++
	}
	t.line_nr++
}

fn (t Tokenizer) error(msg string) {
	eprintln(msg)
	exit(1)
}

fn is_name_start_char(c byte) bool {
	return (c >= `a` && c <= `z`) || (c >= `A` && c <= `Z`) || c == `_`
}

fn is_name_char(c byte) bool {
	return is_name_start_char(c) || (c >= `0` && c <= `9`)
}
