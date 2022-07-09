// This file is part of: bait.
// Copyright (c) 2022 Lukas Neubert.
// Use of this code is governed by an MIT License (see LICENSE.md).
module main

import os
import lib.bait.pref

const tools = ['help']

fn main() {
	args := os.args[1..]
	prefs := pref.parse_args(args)
	if prefs.command in tools {
		ret := launch_tool(prefs.command, args)
		exit(ret)
	}
	eprintln('Unknown command: `bait $prefs.command`')
	exit(1)
}

fn launch_tool(name string, args []string) int {
	exe_root := os.dir(os.real_path(os.executable()))
	mut tool_path := os.join_path(exe_root, 'cmd', 'tools', name)
	if os.is_dir(tool_path) {
		os.join_path(tool_path, name)
	}
	tool_source := tool_path + '.v'
	comp_ret := os.system('v $tool_source')
	if comp_ret != 0 {
		return comp_ret
	}
	arg_string := args.join(' ')
	return os.system('$tool_path $arg_string')
}
