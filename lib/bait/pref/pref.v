// This file is part of: bait programming language
// Copyright (c) 2022 Lukas Neubert
// Use of this code is governed by an MIT License (see LICENSE.md).
module pref

[heap]
pub struct Preferences {
pub mut:
	path     string
	is_test  bool
	out_name string
}
