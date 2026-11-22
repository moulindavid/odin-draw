package main

import rl "vendor:raylib"

SELECTION_HIT_SCREEN_TOLERANCE :: 6.0
SELECTION_SCREEN_PADDING :: 6.0
SELECTION_BORDER_SCREEN_WIDTH :: 1.0
DOUBLE_CLICK_SECONDS :: 0.4
DRAG_START_SCREEN_DISTANCE :: 4.0

Selection :: struct {
	index:           Maybe(int),
	is_dragging:     bool,
	has_moved:       bool,
	wants_text_edit: bool,
	press_position:  rl.Vector2,
	drag_position:   rl.Vector2,
	last_click_time: f64,
}

update_select_tool :: proc(selection: ^Selection, editor: ^Text_Editor, board: ^Board, camera: rl.Camera2D) {
	if is_pan_mode_active() {
		selection.is_dragging = false
		return
	}

	cursor := rl.GetScreenToWorld2D(rl.GetMousePosition(), camera)

	if rl.IsMouseButtonPressed(.LEFT) {
		press_selection(selection, editor, board, cursor, camera.zoom)
	} else if selection.is_dragging && rl.IsMouseButtonDown(.LEFT) {
		drag_selection(selection, board, cursor, camera.zoom)
	} else if selection.is_dragging {
		release_selection(selection, editor, board)
	}
}

press_selection :: proc(selection: ^Selection, editor: ^Text_Editor, board: ^Board, cursor: rl.Vector2, zoom: f32) {
	previous_selection := selection.index
	select_element_at(selection, board^, cursor, SELECTION_HIT_SCREEN_TOLERANCE / zoom)

	_, has_selection := selection.index.?
	selection.wants_text_edit = is_double_click(selection, previous_selection) && is_text_selected(selection^, board^)
	selection.is_dragging = has_selection
	selection.has_moved = false
	selection.press_position = cursor
	selection.drag_position = cursor
}

drag_selection :: proc(selection: ^Selection, board: ^Board, cursor: rl.Vector2, zoom: f32) {
	index, has_selection := selection.index.?
	if !has_selection {
		return
	}

	if !selection.has_moved {
		if rl.Vector2Distance(cursor, selection.press_position) * zoom < DRAG_START_SCREEN_DISTANCE {
			return
		}
		selection.has_moved = true
		selection.wants_text_edit = false
	}

	move_element(board, index, cursor - selection.drag_position)
	selection.drag_position = cursor
}

is_double_click :: proc(selection: ^Selection, previous_selection: Maybe(int)) -> bool {
	now := rl.GetTime()
	defer selection.last_click_time = now

	index, has_selection := selection.index.?
	previous_index, had_selection := previous_selection.?
	is_same_element := has_selection && had_selection && index == previous_index
	return is_same_element && now - selection.last_click_time <= DOUBLE_CLICK_SECONDS
}

release_selection :: proc(selection: ^Selection, editor: ^Text_Editor, board: ^Board) {
	selection.is_dragging = false
	if selection.wants_text_edit {
		open_selected_text(selection, editor, board)
	}
}

is_text_selected :: proc(selection: Selection, board: Board) -> bool {
	index, has_selection := selection.index.?
	if !has_selection {
		return false
	}
	_, is_text := board.elements[index].shape.(Text)
	return is_text
}

open_selected_text :: proc(selection: ^Selection, editor: ^Text_Editor, board: ^Board) {
	index, _ := selection.index.?
	start_editing_existing_text(editor, board, index)
	selection^ = {}
}

update_selection_keys :: proc(selection: ^Selection, board: ^Board) {
	if rl.IsKeyPressed(.DELETE) || rl.IsKeyPressed(.BACKSPACE) {
		delete_selected_element(selection, board)
	}

	if rl.IsKeyPressed(.ESCAPE) {
		selection.index = nil
	}
}

delete_selected_element :: proc(selection: ^Selection, board: ^Board) {
	if index, has_selection := selection.index.?; has_selection {
		remove_element(board, index)
		selection^ = {}
	}
}

select_element_at :: proc(selection: ^Selection, board: Board, point: rl.Vector2, tolerance: f32) {
	if index, found := element_at(board, point, tolerance); found {
		selection.index = index
	} else {
		selection.index = nil
	}
}

element_at :: proc(board: Board, point: rl.Vector2, tolerance: f32) -> (index: int, found: bool) {
	#reverse for element, element_index in board.elements {
		if is_element_hit(element, point, tolerance) {
			return element_index, true
		}
	}
	return
}

is_element_hit :: proc(element: Element, point: rl.Vector2, tolerance: f32) -> bool {
	reach := tolerance + element.stroke_width / 2
	switch shape in element.shape {
	case Freehand:
		return is_near_polyline(shape.points[:], point, reach)
	case Rectangle:
		outline := rectangle_outline(shape.start, shape.end)
		return is_near_polyline(outline[:], point, reach)
	case Ellipse:
		outline := ellipse_points(shape.start, shape.end)
		return is_near_polyline(outline[:], point, reach)
	case Line:
		return distance_to_segment(point, shape.start, shape.end) <= reach
	case Arrow:
		return distance_to_segment(point, shape.start, shape.end) <= reach
	case Text:
		return rl.CheckCollisionPointRec(point, text_bounds(shape))
	}
	return false
}

element_bounds :: proc(element: Element) -> rl.Rectangle {
	bounds: rl.Rectangle
	switch shape in element.shape {
	case Freehand:
		bounds = points_bounds(shape.points[:])
	case Rectangle:
		bounds = rectangle_from_corners(shape.start, shape.end)
	case Ellipse:
		bounds = rectangle_from_corners(shape.start, shape.end)
	case Line:
		bounds = rectangle_from_corners(shape.start, shape.end)
	case Arrow:
		bounds = rectangle_from_corners(shape.start, shape.end)
	case Text:
		bounds = text_bounds(shape)
	}
	return expand_rectangle(bounds, element.stroke_width / 2)
}

draw_selection :: proc(selection: Selection, board: Board, zoom: f32) {
	index, has_selection := selection.index.?
	if !has_selection {
		return
	}
	bounds := expand_rectangle(element_bounds(board.elements[index]), SELECTION_SCREEN_PADDING / zoom)
	rl.DrawRectangleLinesEx(bounds, SELECTION_BORDER_SCREEN_WIDTH / zoom, ACCENT_COLOR)
}
