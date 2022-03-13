module ast

[heap]
pub struct Scope {
pub mut:
	objects  map[string]ScopeObject
	parent   &Scope = 0
	children []&Scope
}

pub struct ScopeObject {
pub:
	name       string
	typ        Type
	auto_deref bool
}

pub fn (mut s Scope) register(var ScopeObject) {
	if var.name in s.objects {
		return
	}
	s.objects[var.name] = var
}

pub fn (s &Scope) find(name string) ScopeObject {
	for scope := s; true; scope = scope.parent {
		if name in scope.objects {
			return scope.objects[name]
		}
		if scope.parent == 0 {
			break
		}
	}
	return ScopeObject{}
}
