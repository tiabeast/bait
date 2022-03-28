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
	name      string
	is_global bool
pub mut:
	typ Type
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

pub fn (mut s Scope) update_type(name string, typ Type) {
	s.objects[name].typ = typ
}
