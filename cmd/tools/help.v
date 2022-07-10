// This file is part of: bait.
// Copyright (c) 2022 Lukas Neubert.
// Use of this code is governed by an MIT License (see LICENSE.md).
import os

fn main() {
	args := os.args[1..]
	if args.len >= 2 {
		try_print_topic(args[1])
	} else {
		try_print_topic('default')
	}
}

fn try_print_topic(topic string) {
	res := read_help_text(topic)
	if res.len == 0 {
		eprintln('Unknown topic: $topic')
		exit(1)
	}
	println(res)
}

fn read_help_text(topic string) string {
	cmd_dir := os.dir(os.dir(os.executable()))
	help_file := os.join_path(cmd_dir, 'help', topic + '.txt')
	if !os.exists(help_file) {
		return ''
	}
	content := os.read_file(help_file) or { panic(err) }
	return content.trim_space()
}
