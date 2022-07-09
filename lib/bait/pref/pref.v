// This file is part of: bait.
// Copyright (c) 2022 Lukas Neubert.
// Use of this code is governed by an MIT License (see LICENSE.md).
module pref

pub struct Preferences {
pub mut:
	command string
}

pub fn parse_args(args []string) Preferences {
	mut p := Preferences{}
	if args.len == 0 {
		p.command = 'help'
		return p
	}
	for i := 0; i < args.len; i++ {
		a := args[i]
		if p.command.len == 0 {
			p.command = a
		}
	}
	return p
}
