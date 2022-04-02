// This file is part of: bait programming language
// Copyright (c) 2022 Lukas Neubert
// Use of this code is governed by an MIT License (see LICENSE.md).
module token

pub struct Position {
pub:
	line_nr int
}

pub fn (p Position) str() string {
	return 'line $p.line_nr'
}
