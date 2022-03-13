module ast

import lib.bait.token

pub type Stmt = AsssignStmt
	| ConstDecl
	| EmptyStmt
	| ExprStmt
	| FunDecl
	| PackageDecl
	| Return
	| StructDecl
pub type Expr = CallExpr | EmptyExpr | Ident | IntegerLiteral | SelectorExpr | StringLiteral

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
	name  string
	scope &Scope
}

pub struct IntegerLiteral {
pub:
	val string
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

pub fn (expr Expr) is_auto_deref() bool {
	if expr is Ident {
		obj := expr.scope.find(expr.name)
		return obj.auto_deref
	}
	return false
}
