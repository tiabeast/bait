// This file is part of: bait.
// Copyright (c) 2022 Lukas Neubert.
// Use of this code is governed by an MIT License (see LICENSE.md).
module main

import os
import lib.bait.pref
import lib.bait.tokenizer

const tools = ['help']

fn main() {
	args := os.args[1..]
	prefs := pref.parse_args(args)
	if prefs.command in tools {
		exit(launch_tool(prefs.command, args))
	}
	if prefs.command.ends_with('.bait') || os.exists(prefs.command) {
		exit(compile(prefs))
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

fn compile(prefs pref.Preferences) int {
	mut paths := bait_files_from_dir(os.resource_abs_path('lib/builtin'))
	paths << get_user_files(prefs.command)
	for p in paths {
		text := os.read_file(p) or { panic(err) }
		tokens := tokenizer.tokenize_text(text)
		// TODO
	}
	// TODO
	return 0
}

fn bait_files_from_dir(dir string) []string {
	mut all_files := os.ls(dir) or { panic(err) }
	mut files := []string{}
	for f in all_files {
		if f.ends_with('.bait') {
			files << f
		}
	}
	files = files.map(os.join_path(dir, it))
	return files
}

fn get_user_files(path string) []string {
	mut user_files := []string{}
	if !os.is_dir(path) && os.exists(path) && path.ends_with('.bait') {
		user_files << path
	} else if os.is_dir(path) {
		user_files << bait_files_from_dir(path)
	}
	return user_files
}
