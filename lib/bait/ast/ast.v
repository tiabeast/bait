// This file is part of: bait.
// Copyright (c) 2022 Lukas Neubert.
// Use of this code is governed by an MIT License (see LICENSE.md).
module ast

import lib.bait.token

pub type Stmt = AssignStmt | EmptyStmt | ExprStmt | FunDecl

pub type Expr = CallExpr | EmptyExpr | Ident | StringLiteral

pub struct AssignStmt {
pub:
	op token.Kind
pub mut:
	left       Expr
	right      Expr
	left_type  Type
	right_type Type
}

pub struct ExprStmt {
pub mut:
	expr Expr
}

pub struct FunDecl {
pub:
	name        string
	params      []Param
	return_type Type
pub mut:
	stmts []Stmt
}

pub struct Param {
pub:
	name string
	typ  Type
}

pub struct CallExpr {
pub:
	name        string
	args        []Expr
	return_type Type
}

pub struct Ident {
pub mut:
	name string
}

pub struct StringLiteral {
pub:
	val string
}

pub struct EmptyStmt {}

pub struct EmptyExpr {}

pub fn empty_expr() Expr {
	return EmptyExpr{}
}

pub struct File {
pub:
	path  string
	stmts []Stmt
}
