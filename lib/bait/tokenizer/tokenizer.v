// This file is part of: bait.
// Copyright (c) 2022 Lukas Neubert.
// Use of this code is governed by an MIT License (see LICENSE.md).
module tokenizer

import lib.bait.token

struct Tokenizer {
	text string
mut:
	pos              int = -1
	line_nr          int = 1
	last_nl_pos      int = -1
	is_inside_string bool
}

pub fn tokenize_text(text string) []token.Token {
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

fn (mut t Tokenizer) text_scan() token.Token {
	for {
		t.pos++
		if !t.is_inside_string {
			t.skip_whitespace()
		}
		if t.pos >= t.text.len {
			return t.new_kind_token(.eof)
		}
		c := t.text[t.pos]
		if is_name_start_char(c) {
			return t.name_or_keyword()
		} else if c.is_digit() {
			num := t.number_literal()
			return t.new_token(.number, num, num.len)
		}
		match c {
			`'`, `"` {
				str := t.string_literal(c)
				return t.new_token(.string, str, str.len + 2) // + two quotes
			}
			`=` {
				if t.next_char() == `=` {
					t.pos++
					return t.new_kind_token(.eq)
				}
			}
			`!` {
				if t.next_char() == `=` {
					t.pos++
					return t.new_kind_token(.ne)
				}
			}
			`(` {
				return t.new_kind_token(.lpar)
			}
			`)` {
				return t.new_kind_token(.rpar)
			}
			`{` {
				return t.new_kind_token(.lcur)
			}
			`}` {
				return t.new_kind_token(.rcur)
			}
			`/` {
				match t.next_char() {
					`/` {
						t.ignore_line()
						continue
					}
					`*` {
						t.block_comment()
						continue
					}
					else {}
				}
			}
			`-` {
				return t.new_kind_token(.minus)
			}
			`,` {
				return t.new_kind_token(.comma)
			}
			`:` {
				if t.next_char() == `=` {
					t.pos++
					return t.new_kind_token(.decl_assign)
				}
			}
			`<` {
				if t.next_char() == `=` {
					t.pos++
					return t.new_kind_token(.le)
				}
				return t.new_kind_token(.lt)
			}
			`>` {
				if t.next_char() == `=` {
					t.pos++
					return t.new_kind_token(.ge)
				}
				return t.new_kind_token(.gt)
			}
			else {}
		}
		t.error('invalid character: $c.ascii_str()')
	}
	return t.new_kind_token(.eof)
}

fn (mut t Tokenizer) name_or_keyword() token.Token {
	name := t.ident_name()
	kind := token.keywords[name]
	if kind != .unknown {
		return t.new_token(kind, '', name.len)
	}
	return t.new_token(.name, name, name.len)
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

fn (mut t Tokenizer) number_literal() string {
	start_pos := t.pos
	for {
		if !t.text[t.pos].is_digit() {
			break
		}
		t.pos++
	}
	if t.text[t.pos] == `.` && t.text[t.pos + 1].is_digit() {
		t.pos++
		for {
			if !t.text[t.pos].is_digit() {
				break
			}
			t.pos++
		}
	}
	lit := t.text[start_pos..t.pos]
	t.pos--
	return lit
}

fn (mut t Tokenizer) string_literal(sep u8) string {
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
		if c == sep {
			t.is_inside_string = false
			break
		}
	}
	return t.text[start_pos..t.pos]
}

fn (mut t Tokenizer) skip_whitespace() {
	for t.pos < t.text.len {
		c := t.text[t.pos]
		if c !in [` `, `\t`, `\n`] {
			return
		}
		if c == `\n` {
			t.line_nr++
			t.last_nl_pos = t.pos
		}
		t.pos++
	}
}

fn (mut t Tokenizer) ignore_line() {
	for t.pos < t.text.len && t.text[t.pos] != `\n` {
		t.pos++
	}
	t.line_nr++
	t.last_nl_pos = t.pos
}

fn (mut t Tokenizer) block_comment() {
	mut nest_count := 1
	t.pos++
	for nest_count > 0 {
		t.pos++
		if t.text[t.pos] == `\n` {
			t.line_nr++
		} else if t.text[t.pos] == `/` && t.text[t.pos + 1] == `*` {
			nest_count++
		} else if t.text[t.pos] == `*` && t.text[t.pos + 1] == `/` {
			nest_count--
		}
	}
	t.pos++
}

fn (t Tokenizer) next_char() u8 {
	return if t.pos + 1 < t.text.len { t.text[t.pos + 1] } else { `\0` }
}

fn (t Tokenizer) new_token(kind token.Kind, lit string, len int) token.Token {
	return token.Token{
		kind: kind
		lit: lit
		pos: token.Position{
			line_nr: t.line_nr
			col: t.column() - len + 1
			len: len
		}
	}
}

fn (t Tokenizer) new_kind_token(kind token.Kind) token.Token {
	return t.new_token(kind, '', 1)
}

fn (t Tokenizer) column() int {
	return t.pos - t.last_nl_pos
}

fn (t Tokenizer) error(msg string) {
	eprintln(msg)
	exit(1)
}

fn is_name_start_char(c char) bool {
	return (c >= `a` && c <= `z`) || (c >= `A` && c <= `Z`) || c == `_`
}

fn is_name_char(c char) bool {
	return is_name_start_char(c) || (c >= `0` && c <= `9`)
}
