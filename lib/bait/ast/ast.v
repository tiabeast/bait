module ast

import lib.bait.token

pub type Stmt = AsssignStmt
	| ConstDecl
	| EmptyStmt
	| ExprStmt
	| ForClassicStmt
	| ForStmt
	| FunDecl
	| PackageDecl
	| Return
	| StructDecl
pub type Expr = BoolLiteral
	| CallExpr
	| EmptyExpr
	| Ident
	| IfExpr
	| InfixExpr
	| IntegerLiteral
	| PrefixExpr
	| SelectorExpr
	| StringLiteral

pub struct EmptyStmt {}

pub struct EmptyExpr {}

pub fn empty_expr() Expr {
	return EmptyExpr{}
}

pub struct AsssignStmt {
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
pub struct ForStmt {
pub mut:
	cond  Expr
	stmts []Stmt
}

// for i := 0; i < 10; i += 1 {}
pub struct ForClassicStmt {
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
pub mut:
	stmts []Stmt
}

pub struct Param {
pub:
	name string
	typ  Type
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
}

pub struct StructField {
pub:
	name string
	typ  Type
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

pub struct Ident {
pub:
	name string
pub mut:
	scope &Scope
}

pub struct IfExpr {
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
	expr       Expr
	field_type Type
}

pub struct StringLiteral {
pub:
	val string
}

[heap]
pub struct File {
pub:
	path string
	pkg  PackageDecl
pub mut:
	stmts []Stmt
}
