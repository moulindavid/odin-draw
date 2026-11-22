package main

import rl "vendor:raylib"

DEFAULT_STROKE_COLOR :: rl.Color{30, 30, 30, 255}
DEFAULT_STROKE_WIDTH :: 2.0

Freehand :: struct {
	points: [dynamic]rl.Vector2,
}

Shape :: union {
	Freehand,
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
	}
}

destroy_board :: proc(board: ^Board) {
	for &element in board.elements {
		destroy_element(&element)
	}
	delete(board.elements)
}
