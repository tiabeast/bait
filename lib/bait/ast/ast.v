// This file is part of: bait.
// Copyright (c) 2022 Lukas Neubert.
// Use of this code is governed by an MIT License (see LICENSE.md).
module ast

import lib.bait.token

pub type Stmt = AssertStmt
	| AssignStmt
	| ConstDecl
	| EmptyStmt
	| EnumDecl
	| ExprStmt
	| ForClassicLoop
	| ForLoop
	| FunDecl
	| GlobalDecl
	| Import
	| LoopControlStmt
	| PackageDecl
	| Return
	| StructDecl
	| TypeDecl
pub type Expr = ArrayInit
	| BoolLiteral
	| CBlock
	| CallExpr
	| CastExpr
	| CharLiteral
	| EmptyExpr
	| EnumVal
	| FloatLiteral
	| Ident
	| IfExpr
	| IndexExpr
	| InfixExpr
	| IntegerLiteral
	| MapInit
	| MatchExpr
	| ParExpr
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
	typ  Type
}

pub struct EnumDecl {
pub:
	name        string
	field_names []string
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

pub struct Import {
pub:
	name  string
	alias string
}

pub struct LoopControlStmt {
pub:
	kind token.Kind
}

pub struct PackageDecl {
pub:
	name      string
	full_name string
}

pub struct Return {
pub mut:
	needs_tmp_var bool
	expr          Expr
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

pub struct TypeDecl {
	name     string
	typ      Type
	variants []Type
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

pub struct CBlock {
pub:
	val string
}

pub struct CallExpr {
pub:
	pkg       string
	lang      Language
	is_method bool
pub mut:
	name        string
	args        []CallArg
	return_type Type
	left        Expr // receiver or IndexExpr
	left_type   Type
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

pub struct EnumVal {
pub:
	enum_name string
	val       string
pub mut:
	typ Type
}

pub struct FloatLiteral {
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
	pkg  string
	lang Language
pub mut:
	name  string
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
	index       Expr
	left        Expr
	left_type   Type
	is_selector bool
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

pub struct MapInit {
pub mut:
	typ      Type
	key_type Type
	val_type Type
	keys     []Expr
	vals     []Expr
}

pub struct MatchExpr {
pub mut:
	is_expr   bool
	cond      Expr
	cond_type Type
	branches  []MatchBranch
}

pub struct MatchBranch {
pub mut:
	val   Expr
	stmts []Stmt
}

pub struct ParExpr {
pub mut:
	expr Expr
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
	imports []Import
pub mut:
	stmts []Stmt
}
