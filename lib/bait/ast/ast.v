// This file is part of: bait programming language
// Copyright (c) 2022 Lukas Neubert
// Use of this code is governed by an MIT License (see LICENSE.md).
module ast

import lib.bait.token

pub type Stmt = AssertStmt
	| AssignStmt
	| ConstDecl
	| EmptyStmt
	| ExprStmt
	| ForClassicLoop
	| ForLoop
	| FunDecl
	| GlobalDecl
	| PackageDecl
	| Return
	| StructDecl
pub type Expr = ArrayInit
	| BoolLiteral
	| CallExpr
	| CastExpr
	| CharLiteral
	| EmptyExpr
	| Ident
	| IfExpr
	| IndexExpr
	| InfixExpr
	| IntegerLiteral
	| PrefixExpr
	| SelectorExpr
	| StringLiteral
	| StructInit

pub struct EmptyStmt {}

pub struct EmptyExpr {}

pub fn empty_expr() Expr {
	return EmptyExpr{}
}

pub struct AssertStmt {
pub:
	pos token.Position
pub mut:
	expr Expr
}

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

// for cond {}
pub struct ForLoop {
pub mut:
	cond  Expr
	stmts []Stmt
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
	is_method   bool
	is_test     bool
pub mut:
	stmts []Stmt
}

pub struct Param {
pub:
	name string
	typ  Type
}

pub struct GlobalDecl {
pub:
	name string
	typ  Type
pub mut:
	expr Expr
}

pub struct PackageDecl {
pub:
	name string
}

pub struct Return {
pub mut:
	expr Expr
}

pub struct StructDecl {
	name   string
	fields []StructField
}

pub struct StructField {
pub:
	name string
	typ  Type
}

pub struct ArrayInit {
pub mut:
	exprs     []Expr
	arr_type  Type
	elem_type Type
	len_expr  Expr
	cap_expr  Expr
}

pub struct BoolLiteral {
pub:
	val bool
}

pub struct CallExpr {
pub:
	pkg       string
	lang      Language
	is_method bool
pub mut:
	name          string
	args          []CallArg
	return_type   Type
	receiver      Expr
	receiver_type Type
}

pub struct CallArg {
pub mut:
	expr Expr
}

pub struct CastExpr {
pub:
	target_type Type
pub mut:
	expr Expr
}

pub struct CharLiteral {
pub:
	val string
}

pub enum IdentKind {
	unresolved
	variable
	constant
	global
}

pub struct Ident {
pub:
	name string
pub mut:
	kind  IdentKind
	scope &Scope
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

pub struct IndexExpr {
pub mut:
	index     Expr
	left      Expr
	left_type Type
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

pub struct PrefixExpr {
pub mut:
	right      Expr
	right_type Type
pub:
	op token.Kind
}

pub struct SelectorExpr {
pub:
	field_name string
pub mut:
	field_type Type
	expr       Expr
	expr_type  Type
}

pub struct StringLiteral {
pub:
	val string
}

pub struct StructInit {
pub:
	typ    Type
	fields []StructInitField
}

pub struct StructInitField {
pub mut:
	expr Expr
	typ  Type
pub:
	name     string
	exp_type Type
}

[heap]
pub struct File {
pub:
	path    string
	is_test bool
	pkg     PackageDecl
pub mut:
	stmts []Stmt
}
