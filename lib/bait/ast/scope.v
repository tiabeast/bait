// This file is part of: bait.
// Copyright (c) 2022 Lukas Neubert.
// Use of this code is governed by an MIT License (see LICENSE.md).
module ast

[heap]
pub struct Scope {
pub:
	parent &Scope
}
