package main

import "core:slice"
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

clone_element :: proc(element: Element) -> Element {
	clone := element
	switch shape in element.shape {
	case Freehand:
		clone.shape = Freehand{slice.clone_to_dynamic(shape.points[:])}
	case Text:
		text := shape
		text.content = strings.clone(shape.content)
		clone.shape = text
	case Rectangle, Ellipse, Line, Arrow:
	}
	return clone
}

clone_elements :: proc(elements: []Element) -> []Element {
	copies := make([]Element, len(elements))
	for element, index in elements {
		copies[index] = clone_element(element)
	}
	return copies
}

elements_equal :: proc(a, b: []Element) -> bool {
	if len(a) != len(b) {
		return false
	}
	for index in 0 ..< len(a) {
		if !element_equal(a[index], b[index]) {
			return false
		}
	}
	return true
}

element_equal :: proc(a, b: Element) -> bool {
	return a.color == b.color && a.stroke_width == b.stroke_width && shapes_equal(a.shape, b.shape)
}

shapes_equal :: proc(a, b: Shape) -> bool {
	switch shape in a {
	case Freehand:
		other, same_kind := b.(Freehand)
		return same_kind && slice.equal(shape.points[:], other.points[:])
	case Rectangle:
		other, same_kind := b.(Rectangle)
		return same_kind && shape == other
	case Ellipse:
		other, same_kind := b.(Ellipse)
		return same_kind && shape == other
	case Line:
		other, same_kind := b.(Line)
		return same_kind && shape == other
	case Arrow:
		other, same_kind := b.(Arrow)
		return same_kind && shape == other
	case Text:
		other, same_kind := b.(Text)
		return same_kind && shape.position == other.position && shape.content == other.content && shape.font_size == other.font_size
	}
	return b == nil
}

destroy_elements :: proc(elements: []Element) {
	for &element in elements {
		destroy_element(&element)
	}
	delete(elements)
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

replace_elements :: proc(board: ^Board, elements: []Element) {
	for &element in board.elements {
		destroy_element(&element)
	}
	clear(&board.elements)
	for element in elements {
		append(&board.elements, clone_element(element))
	}
	board.revision += 1
}

destroy_board :: proc(board: ^Board) {
	for &element in board.elements {
		destroy_element(&element)
	}
	delete(board.elements)
}
