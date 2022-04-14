// This file is part of: bait.
// Copyright (c) 2022 Lukas Neubert.
// Use of this code is governed by an MIT License (see LICENSE.md).
module main

import os
import lib.bait.ast
import lib.bait.pref
import lib.bait.tokenizer
import lib.bait.parser
import lib.bait.checker
import lib.bait.gen.c as cgen

fn main() {
	args := os.args[1..]
	if args.len == 0 {
		launch_bait_tool('help', args)
	}
	prefs, command := parse_args(args)
	match command {
		'help' {
			launch_bait_tool('help', args)
		}
		'test' {
			run_tests(args[1..], prefs)
			return
		}
		else {}
	}
	if command.ends_with('.bait') || os.exists(command) {
		exit(compile(command, prefs))
	}
	eprintln('Unknown command: `bait $command`')
	exit(1)
}

fn parse_args(args []string) (&pref.Preferences, string) {
	mut p := &pref.Preferences{}
	mut command := ''
	for i := 0; i < args.len; i++ {
		arg := args[i]
		match arg {
			'-o', '--output' {
				p.out_name = args[i + 1]
				i++
			}
			else {
				if command.len == 0 {
					command = arg
				}
			}
		}
	}
	if p.out_name.len == 0 {
		p.out_name = command.replace('.bait', '')
	}
	if command == 'test' {
		p.is_test = true
	}
	return p, command
}

fn compile(path string, prefs &pref.Preferences) int {
	mut paths := bait_files_from_dir(os.resource_abs_path('lib/builtin'))
	paths << get_user_files(path, prefs)
	mut table := ast.new_table()
	mut files := []&ast.File{}
	for p in paths {
		tokens := tokenizer.tokenize_file(p)
		files << parser.parse_tokens(tokens, p, table)
	}
	pkg_name := files.last().pkg.name
	for i := 0; i < files.len; i++ {
		f := files[i]
		for imp in f.imports {
			imp_path := imp.name.replace('.', '/')
			imp_paths := bait_files_from_dir(os.resource_abs_path('lib/$imp_path'))
			for p in imp_paths.filter(it !in paths) {
				paths << p
				tokens := tokenizer.tokenize_file(p)
				files << parser.parse_tokens(tokens, p, table)
			}
		}
	}
	mut deps := map[string][]string{}
	for f in files {
		if f.pkg.name != 'builtin' {
			deps[f.pkg.name] << 'builtin'
		}
		for imp in f.imports {
			deps[f.pkg.name] << imp.name
		}
	}
	mut ordered := []string{}
	order_deps(mut ordered, pkg_name, deps)
	mut reordered_files := []&ast.File{}
	for pkg in ordered {
		for f in files {
			if pkg == f.pkg.name {
				reordered_files << f
			}
		}
	}
	mut checker := checker.Checker{
		table: table
	}
	checker.check_files(reordered_files)
	if checker.errors.len > 0 {
		for err in checker.errors {
			eprintln(err)
		}
		return 1
	}
	res := cgen.gen(reordered_files, table, prefs)
	tmp_c_path := os.temp_dir() + '/a.tmp.c'
	os.write_file(tmp_c_path, res) or { panic(err) }
	mut out_file := prefs.out_name
	if !out_file.starts_with('/') {
		out_file = os.getwd() + '/' + out_file
	}
	cmd_res := os.execute('cc -o "$out_file" "$tmp_c_path"')
	if cmd_res.output.len > 0 {
		eprintln(cmd_res.output)
	}
	if cmd_res.exit_code != 0 {
		return 1
	}
	return 0
}

fn run_tests(args []string, prefs &pref.Preferences) {
	mut files_to_test := []string{}
	for a in args {
		if os.is_dir(a) {
			files_to_test << test_files_from_dir_recursive(a)
		} else if os.exists(a) {
			if a.ends_with('_test.bait') {
				files_to_test << a
			}
		} else {
			eprintln('Unrecognized file or directory: "$a"')
			exit(1)
		}
	}
	files_to_test.sort()
	mut has_fails := false
	for i, file in files_to_test {
		real_path := os.real_path(file)
		mut test_prefs := prefs
		test_prefs.path = file
		test_prefs.out_name = os.temp_dir() + '/test_$i'
		res := compile(real_path, test_prefs)
		if res != 0 {
			has_fails = true
			println('FAIL $file')
			continue
		}
		runres := os.execute(test_prefs.out_name)
		if runres.exit_code == 0 {
			println('OK $file')
		} else {
			has_fails = true
			println('FAIL $file')
			println(runres.output)
		}
	}
	if has_fails {
		exit(1)
	}
	exit(0)
}

fn test_files_from_dir_recursive(dir string) []string {
	mut files := os.ls(dir) or { return []string{} }
	mut res_files := []string{}
	for file in files {
		p := os.join_path(dir, file)
		if os.is_dir(p) {
			res_files << test_files_from_dir_recursive(p)
		} else if os.exists(p) {
			if p.ends_with('_test.bait') {
				res_files << p
			}
		}
	}
	return res_files
}

fn get_user_files(_path string, prefs &pref.Preferences) []string {
	mut path := _path
	mut user_files := []string{}
	mut is_internal_module_test := false
	if prefs.is_test {
		content := os.read_file(path) or { panic(err) }
		lines := content.split_into_lines()
		for line in lines {
			if line.starts_with('package ') {
				if line.starts_with('package main') {
					break
				}
				is_internal_module_test = true
				break
			}
		}
	}
	if is_internal_module_test {
		user_files << path
		path = os.dir(path)
	}
	if !os.is_dir(path) && os.exists(path) && path.ends_with('.bait') {
		user_files << path
	} else if os.is_dir(path) {
		user_files << bait_files_from_dir(path)
	}
	return user_files
}

fn bait_files_from_dir(dir string) []string {
	mut all_files := os.ls(dir) or { panic(err) }
	mut files := []string{}
	for f in all_files {
		if f.ends_with('_test.bait') {
			continue
		}
		if f.ends_with('.bait') {
			files << f
		}
	}
	files = files.map(os.join_path(dir, it))
	return files
}

fn should_recompile_tool(tool_exe string, tool_source string) bool {
	if !os.exists(tool_exe) {
		return true
	}
	last_exe_mod := os.file_last_mod_unix(tool_exe)
	last_source_mod := os.file_last_mod_unix(tool_source)
	if last_exe_mod <= last_source_mod {
		return true
	}
	// TODO check for modified imports, until then return always true
	return true
}

fn launch_bait_tool(name string, args []string) {
	exe := os.executable()
	exe_root := os.dir(os.real_path(exe))
	tool_path := os.join_path(exe_root, 'cmd', 'tools', name)
	tool_source := tool_path + '.bait'
	if should_recompile_tool(tool_path, tool_source) {
		cret := os.system('bait "$tool_source"')
		if cret != 0 {
			exit(cret)
		}
	}
	tool_args := args.join(' ')
	exit(os.system('$tool_path $tool_args'))
}

fn order_deps(mut ordered []string, mod string, deps map[string][]string) []string {
	for d in deps[mod] {
		order_deps(mut ordered, d, deps)
	}
	if mod !in ordered {
		ordered << mod
	}
	return ordered
}
