package main

import rl "vendor:raylib"

HANDLE_SCREEN_SIZE :: 8.0
HANDLE_HIT_SCREEN_SIZE :: 14.0
HANDLE_BORDER_SCREEN_WIDTH :: 1.5
MIN_TEXT_FONT_SIZE :: 6.0

Handle :: enum {
	Top_Left,
	Top,
	Top_Right,
	Right,
	Bottom_Right,
	Bottom,
	Bottom_Left,
	Left,
	Start,
	End,
}

Handles :: bit_set[Handle]

BOX_HANDLES :: Handles{.Top_Left, .Top, .Top_Right, .Right, .Bottom_Right, .Bottom, .Bottom_Left, .Left}
CORNER_HANDLES :: Handles{.Top_Left, .Top_Right, .Bottom_Right, .Bottom_Left}
ENDPOINT_HANDLES :: Handles{.Start, .End}

Resize :: struct {
	handle:   Handle,
	original: Element,
}

element_handles :: proc(element: Element) -> Handles {
	switch _ in element.shape {
	case Freehand, Rectangle, Ellipse:
		return BOX_HANDLES
	case Line, Arrow:
		return ENDPOINT_HANDLES
	case Text:
		return CORNER_HANDLES
	}
	return {}
}

handle_position :: proc(element: Element, handle: Handle, zoom: f32) -> rl.Vector2 {
	#partial switch shape in element.shape {
	case Line:
		return shape.start if handle == .Start else shape.end
	case Arrow:
		return shape.start if handle == .Start else shape.end
	}

	frame := selection_frame(element, zoom)
	horizontal, vertical := handle_sides(handle)
	center := rl.Vector2{frame.x + frame.width / 2, frame.y + frame.height / 2}
	return center + {f32(horizontal) * frame.width / 2, f32(vertical) * frame.height / 2}
}

handle_sides :: proc(handle: Handle) -> (horizontal, vertical: int) {
	switch handle {
	case .Top_Left:
		return -1, -1
	case .Top:
		return 0, -1
	case .Top_Right:
		return 1, -1
	case .Right:
		return 1, 0
	case .Bottom_Right:
		return 1, 1
	case .Bottom:
		return 0, 1
	case .Bottom_Left:
		return -1, 1
	case .Left:
		return -1, 0
	case .Start, .End:
		return 0, 0
	}
	return 0, 0
}

handle_at :: proc(element: Element, point: rl.Vector2, zoom: f32) -> (handle: Handle, found: bool) {
	reach := HANDLE_HIT_SCREEN_SIZE / 2 / zoom
	for candidate in element_handles(element) {
		offset := point - handle_position(element, candidate, zoom)
		if abs(offset.x) <= reach && abs(offset.y) <= reach {
			return candidate, true
		}
	}
	return
}

handle_cursor :: proc(handle: Handle) -> rl.MouseCursor {
	switch handle {
	case .Top_Left, .Bottom_Right:
		return .RESIZE_NWSE
	case .Top_Right, .Bottom_Left:
		return .RESIZE_NESW
	case .Top, .Bottom:
		return .RESIZE_NS
	case .Left, .Right:
		return .RESIZE_EW
	case .Start, .End:
		return .CROSSHAIR
	}
	return .DEFAULT
}

resize_element :: proc(board: ^Board, index: int, resize: Resize, offset: rl.Vector2) {
	board.revision += 1
	from := shape_bounds(resize.original.shape)
	to := resized_bounds(from, resize.handle, offset)

	switch &shape in board.elements[index].shape {
	case Freehand:
		original := resize.original.shape.(Freehand)
		for &point, point_index in shape.points {
			point = map_point(original.points[point_index], from, to)
		}
	case Rectangle:
		original := resize.original.shape.(Rectangle)
		shape.start = map_point(original.start, from, to)
		shape.end = map_point(original.end, from, to)
	case Ellipse:
		original := resize.original.shape.(Ellipse)
		shape.start = map_point(original.start, from, to)
		shape.end = map_point(original.end, from, to)
	case Line:
		original := resize.original.shape.(Line)
		shape.start, shape.end = moved_endpoints(original.start, original.end, resize.handle, offset)
	case Arrow:
		original := resize.original.shape.(Arrow)
		shape.start, shape.end = moved_endpoints(original.start, original.end, resize.handle, offset)
	case Text:
		scale_text(&shape, resize.original.shape.(Text), resize.handle, offset)
	}
}

resized_bounds :: proc(bounds: rl.Rectangle, handle: Handle, offset: rl.Vector2) -> rl.Rectangle {
	horizontal, vertical := handle_sides(handle)
	resized := bounds
	switch horizontal {
	case -1:
		resized.x += offset.x
		resized.width -= offset.x
	case 1:
		resized.width += offset.x
	}
	switch vertical {
	case -1:
		resized.y += offset.y
		resized.height -= offset.y
	case 1:
		resized.height += offset.y
	}
	return resized
}

map_point :: proc(point: rl.Vector2, from, to: rl.Rectangle) -> rl.Vector2 {
	return {
		map_coordinate(point.x, from.x, from.width, to.x, to.width),
		map_coordinate(point.y, from.y, from.height, to.y, to.height),
	}
}

map_coordinate :: proc(value, from_start, from_size, to_start, to_size: f32) -> f32 {
	if from_size == 0 {
		return value + to_start - from_start
	}
	return to_start + (value - from_start) * to_size / from_size
}

moved_endpoints :: proc(start, end: rl.Vector2, handle: Handle, offset: rl.Vector2) -> (rl.Vector2, rl.Vector2) {
	if handle == .Start {
		return start + offset, end
	}
	return start, end + offset
}

scale_text :: proc(text: ^Text, original: Text, handle: Handle, offset: rl.Vector2) {
	from := text_bounds(original)
	to := resized_bounds(from, handle, offset)
	scale := (to.width / from.width + to.height / from.height) / 2
	text.font_size = max(MIN_TEXT_FONT_SIZE, original.font_size * scale)

	size := measure_text_block(text.content, text.font_size)
	horizontal, vertical := handle_sides(handle)
	text.position = {from.x, from.y}
	if horizontal < 0 {
		text.position.x = from.x + from.width - size.x
	}
	if vertical < 0 {
		text.position.y = from.y + from.height - size.y
	}
}

draw_handles :: proc(element: Element, zoom: f32) {
	size := HANDLE_SCREEN_SIZE / zoom
	for handle in element_handles(element) {
		center := handle_position(element, handle, zoom)
		square := rl.Rectangle{center.x - size / 2, center.y - size / 2, size, size}
		rl.DrawRectangleRec(square, rl.WHITE)
		rl.DrawRectangleLinesEx(square, HANDLE_BORDER_SCREEN_WIDTH / zoom, ACCENT_COLOR)
	}
}
