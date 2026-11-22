package main

import "core:encoding/json"
import "core:os"
import "core:slice"
import "core:strings"
import rl "vendor:raylib"

BOARD_FILE_VERSION :: 1

Board_File :: struct {
	version:  int,
	elements: []Element_Record,
}

Shape_Kind :: enum {
	Freehand,
	Rectangle,
	Ellipse,
	Line,
	Arrow,
	Text,
}

Element_Record :: struct {
	kind:         Shape_Kind,
	color:        rl.Color,
	stroke_width: f32,
	points:       []rl.Vector2,
	text:         string `json:"text,omitempty"`,
	font_size:    f32,
}

save_board :: proc(board: Board, path: string) -> bool {
	records := make([]Element_Record, len(board.elements), context.temp_allocator)
	for element, index in board.elements {
		records[index] = element_to_record(element)
	}

	file := Board_File {
		version  = BOARD_FILE_VERSION,
		elements = records,
	}
	data, marshal_error := json.marshal(file, {use_enum_names = true}, context.temp_allocator)
	if marshal_error != nil {
		return false
	}
	return os.write_entire_file(path, data) == nil
}

load_board :: proc(board: ^Board, path: string) -> bool {
	data, read_error := os.read_entire_file(path, context.temp_allocator)
	if read_error != nil {
		return false
	}

	file: Board_File
	if json.unmarshal(data, &file, allocator = context.temp_allocator) != nil {
		return false
	}

	loaded: [dynamic]Element
	for record in file.elements {
		element, is_valid := record_to_element(record)
		if !is_valid {
			destroy_elements(loaded[:])
			return false
		}
		append(&loaded, element)
	}
	set_elements(board, loaded)
	return true
}

element_to_record :: proc(element: Element) -> Element_Record {
	record := Element_Record {
		color        = element.color,
		stroke_width = element.stroke_width,
	}
	switch shape in element.shape {
	case Freehand:
		record.kind = .Freehand
		record.points = shape.points[:]
	case Rectangle:
		record.kind = .Rectangle
		record.points = record_points(shape.start, shape.end)
	case Ellipse:
		record.kind = .Ellipse
		record.points = record_points(shape.start, shape.end)
	case Line:
		record.kind = .Line
		record.points = record_points(shape.start, shape.end)
	case Arrow:
		record.kind = .Arrow
		record.points = record_points(shape.start, shape.end)
	case Text:
		record.kind = .Text
		record.points = record_points(shape.position)
		record.text = shape.content
		record.font_size = shape.font_size
	}
	return record
}

record_points :: proc(points: ..rl.Vector2) -> []rl.Vector2 {
	return slice.clone(points, context.temp_allocator)
}

record_to_element :: proc(record: Element_Record) -> (element: Element, is_valid: bool) {
	element.color = record.color
	element.stroke_width = record.stroke_width
	points := record.points

	switch record.kind {
	case .Freehand:
		if len(points) == 0 {
			return
		}
		element.shape = Freehand{slice.clone_to_dynamic(points)}
	case .Rectangle:
		if len(points) != 2 {
			return
		}
		element.shape = Rectangle{points[0], points[1]}
	case .Ellipse:
		if len(points) != 2 {
			return
		}
		element.shape = Ellipse{points[0], points[1]}
	case .Line:
		if len(points) != 2 {
			return
		}
		element.shape = Line{points[0], points[1]}
	case .Arrow:
		if len(points) != 2 {
			return
		}
		element.shape = Arrow{points[0], points[1]}
	case .Text:
		if len(points) != 1 {
			return
		}
		element.shape = Text{points[0], strings.clone(record.text), record.font_size}
	}
	return element, true
}
