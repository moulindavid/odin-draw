package main

import "core:strings"
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

Text :: struct {
	position:  rl.Vector2,
	content:   string,
	font_size: f32,
}

Shape :: union {
	Freehand,
	Rectangle,
	Ellipse,
	Line,
	Arrow,
	Text,
}

Element :: struct {
	shape:        Shape,
	color:        rl.Color,
	stroke_width: f32,
}

Board :: struct {
	elements: [dynamic]Element,
	revision: int,
}

add_element :: proc(board: ^Board, element: Element) {
	append(&board.elements, element)
	board.revision += 1
}

insert_element :: proc(board: ^Board, index: int, element: Element) {
	inject_at(&board.elements, index, element)
	board.revision += 1
}

take_element :: proc(board: ^Board, index: int) -> Element {
	element := board.elements[index]
	ordered_remove(&board.elements, index)
	board.revision += 1
	return element
}

remove_element :: proc(board: ^Board, index: int) {
	element := take_element(board, index)
	destroy_element(&element)
}

text_element_at :: proc(board: Board, point: rl.Vector2) -> (index: int, found: bool) {
	#reverse for element, element_index in board.elements {
		text, is_text := element.shape.(Text)
		if is_text && rl.CheckCollisionPointRec(point, text_bounds(text)) {
			return element_index, true
		}
	}
	return
}

move_element :: proc(board: ^Board, index: int, offset: rl.Vector2) {
	board.revision += 1
	switch &shape in board.elements[index].shape {
	case Freehand:
		for &point in shape.points {
			point += offset
		}
	case Rectangle:
		shape.start += offset
		shape.end += offset
	case Ellipse:
		shape.start += offset
		shape.end += offset
	case Line:
		shape.start += offset
		shape.end += offset
	case Arrow:
		shape.start += offset
		shape.end += offset
	case Text:
		shape.position += offset
	}
}

destroy_element :: proc(element: ^Element) {
	switch &shape in element.shape {
	case Freehand:
		delete(shape.points)
	case Text:
		delete(shape.content)
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
	case Text:
		return strings.trim_space(s.content) == ""
	}
	return true
}

destroy_board :: proc(board: ^Board) {
	for &element in board.elements {
		destroy_element(&element)
	}
	delete(board.elements)
}
