module main

import os
import lib.bait.ast
import lib.bait.tokenizer
import lib.bait.parser
import lib.bait.checker
import lib.bait.gen.c as cgen

fn main() {
	args := os.args[1..]
	if args.len == 0 || args[0] == 'help' {
		println('help coming soon')
		exit(0)
	}
	if args[0].ends_with('.bait') || os.exists(args[0]) {
		compile(args[0])
		exit(0)
	}
	eprintln('Unknown command: `bait ${args[0]}`')
	exit(1)
}

fn compile(path string) {
	mut paths := bait_files_from_dir(os.resource_abs_path('lib/builtin'))
	if !os.is_dir(path) && os.exists(path) && path.ends_with('.bait') {
		paths << path
	} else if os.is_dir(path) {
		paths << bait_files_from_dir(path)
	} else {
		eprintln('Unrecognized file or directory: "$path"')
		exit(1)
	}
	mut table := ast.new_table()
	mut files := []&ast.File{}
	for p in paths {
		tokens := tokenizer.tokenize_file(p)
		files << parser.parse_tokens(tokens, p, table)
	}
	mut checker := checker.Checker{
		table: table
	}
	checker.check_files(files)
	if checker.errors.len > 0 {
		for err in checker.errors {
			eprintln(err)
		}
		exit(1)
	}
	res := cgen.gen(files, table)
	tmp_c_path := os.temp_dir() + '/a.tmp.c'
	os.write_file(tmp_c_path, res) or { panic(err) }
	out_file := os.getwd() + '/a.out'
	cmd_res := os.execute('cc -o "$out_file" "$tmp_c_path"')
	if cmd_res.output.len > 0 {
		eprintln(cmd_res.output)
	}
	if cmd_res.exit_code != 0 {
		exit(1)
	}
}

fn bait_files_from_dir(dir string) []string {
	mut files := os.ls(dir) or { panic(err) }
	files = files.filter(it.ends_with('.bait'))
	files = files.map(os.join_path(dir, it))
	return files
}
