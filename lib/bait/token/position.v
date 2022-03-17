module token

pub struct Position {
pub:
	line_nr int
}

pub fn (p Position) str() string {
	return 'line $p.line_nr'
}
