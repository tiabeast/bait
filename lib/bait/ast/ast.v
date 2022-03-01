module ast

pub type Stmt = EmptyStmt | ExprStmt | FunDecl | PackageDecl | StructDecl
pub type Expr = CallExpr | EmptyExpr | Ident | SelectorExpr | StringLiteral

pub struct EmptyStmt {}

pub struct EmptyExpr {}

pub fn empty_expr() Expr {
	return EmptyExpr{}
}

pub struct ExprStmt {
pub:
	expr Expr
}

pub struct FunDecl {
pub:
	name        string
	params      []Param
	return_type Type
	stmts       []Stmt
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

pub struct StructDecl {
}

pub struct StructField {
pub:
	name string
	typ  Type
}

pub struct CallExpr {
pub:
	name string
	args []CallArg
	lang Language
}

pub struct CallArg {
pub:
	expr Expr
}

pub struct Ident {
pub:
	name string
}

pub struct SelectorExpr {
pub:
	expr       Expr
	field_name string
pub mut:
	field_type Type
}

pub struct StringLiteral {
pub:
	val string
}

pub struct File {
pub:
	path  string
	pkg   PackageDecl
	stmts []Stmt
}
