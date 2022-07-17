// This file is part of: bait.
// Copyright (c) 2022 Lukas Neubert.
// Use of this code is governed by an MIT License (see LICENSE.md).
module ast

import lib.bait.token

pub type Stmt = AssignStmt
	| ConstDecl
	| EmptyStmt
	| ExprStmt
	| ForClassicLoop
	| FunDecl
	| PackageDecl

pub type Expr = BoolLiteral
	| CallExpr
	| EmptyExpr
	| FloatLiteral
	| Ident
	| IfExpr
	| InfixExpr
	| IntegerLiteral
	| StringLiteral

pub struct AssignStmt {
pub:
	op token.Kind
pub mut:
	left       Expr
	right      Expr
	left_type  Type
	right_type Type
}

pub struct ConstDecl {
pub mut:
	name string
	expr Expr
}

pub struct ExprStmt {
pub mut:
	expr Expr
}

// for i := 0; i < 10; i += 1 {}
pub struct ForClassicLoop {
pub mut:
	init  Stmt
	cond  Expr
	inc   Stmt
	stmts []Stmt
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

pub struct Import {
pub:
	name string
}

pub struct PackageDecl {
pub:
	no_package bool
	name       string
	full_name  string
}

pub struct BoolLiteral {
pub:
	val bool
}

pub struct CallExpr {
pub mut:
	name     string
	pkg_name string
	lang     Language
	left     Expr
	args     []Expr
pub:
	return_type Type
	is_method   bool
}

pub struct FloatLiteral {
pub:
	val string
}

pub struct Ident {
pub mut:
	name string
}

pub struct IfExpr {
pub:
	has_else bool
pub mut:
	branches []IfBranch
}

pub struct IfBranch {
pub mut:
	cond  Expr
	stmts []Stmt
}

pub struct InfixExpr {
pub mut:
	left       Expr
	right      Expr
	left_type  Type
	right_type Type
pub:
	op token.Kind
}

pub struct IntegerLiteral {
pub:
	val string
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
pub mut:
	stmts   []Stmt
	imports []Import
pub:
	path string
}
