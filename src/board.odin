package main

import rl "vendor:raylib"

DEFAULT_STROKE_COLOR :: rl.Color{30, 30, 30, 255}
DEFAULT_STROKE_WIDTH :: 2.0

Freehand :: struct {
	points: [dynamic]rl.Vector2,
}

Rectangle :: struct {
	start, end: rl.Vector2,
}

Ellipse :: struct {
	start, end: rl.Vector2,
}

Line :: struct {
	start, end: rl.Vector2,
}

Arrow :: struct {
	start, end: rl.Vector2,
}

Shape :: union {
	Freehand,
	Rectangle,
	Ellipse,
	Line,
	Arrow,
}

Element :: struct {
	shape:        Shape,
	color:        rl.Color,
	stroke_width: f32,
}

Board :: struct {
	elements: [dynamic]Element,
}

add_element :: proc(board: ^Board, element: Element) {
	append(&board.elements, element)
}

destroy_element :: proc(element: ^Element) {
	switch &shape in element.shape {
	case Freehand:
		delete(shape.points)
	case Rectangle, Ellipse, Line, Arrow:
	}
}

is_empty_shape :: proc(shape: Shape) -> bool {
	switch s in shape {
	case Freehand:
		return len(s.points) == 0
	case Rectangle:
		return s.start == s.end
	case Ellipse:
		return s.start == s.end
	case Line:
		return s.start == s.end
	case Arrow:
		return s.start == s.end
	}
	return true
}

destroy_board :: proc(board: ^Board) {
	for &element in board.elements {
		destroy_element(&element)
	}
	delete(board.elements)
}
