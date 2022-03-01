module ast

[heap]
pub struct Scope {
pub mut:
	objects  map[string]ScopeVar
	parent   &Scope = 0
	children []&Scope
}

pub struct ScopeVar {
	name string
	typ  Type
}

pub fn (mut s Scope) register(var ScopeVar) {
	if var.name in s.objects {
		return
	}
	s.objects[var.name] = var
}
