// This file is part of: bait.
// Copyright (c) 2022 Lukas Neubert.
// Use of this code is governed by an MIT License (see LICENSE.md).
module ast

pub enum Language {
	bait
	v
}

pub fn (l Language) src_str() string {
	return match l {
		.bait { '' }
		.v { '@v.' }
	}
}
