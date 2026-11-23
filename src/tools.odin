package main

import rl "vendor:raylib"

FREEHAND_MIN_SCREEN_STEP :: 2.0

Tool :: enum {
	Select,
	Rectangle,
	Ellipse,
	Arrow,
	Line,
	Freehand,
	Text,
}

@(rodata)
TOOL_SHORTCUTS := [Tool][2]rl.KeyboardKey {
	.Select    = {.V, .ONE},
	.Rectangle = {.R, .TWO},
	.Ellipse   = {.O, .THREE},
	.Arrow     = {.A, .FOUR},
	.Line      = {.L, .FIVE},
	.Freehand  = {.P, .SIX},
	.Text      = {.T, .SEVEN},
}

tool_from_shortcuts :: proc(current: Tool) -> Tool {
	if is_control_down() {
		return current
	}
	for keys, tool in TOOL_SHORTCUTS {
		for key in keys {
			if rl.IsKeyPressed(key) {
				return tool
			}
		}
	}
	return current
}

Draft :: struct {
	element:   Element,
	is_active: bool,
}

update_drawing :: proc(tool: Tool, draft: ^Draft, board: ^Board, camera: rl.Camera2D) {
	if draft.is_active && (is_pan_mode_active() || !rl.IsMouseButtonDown(.LEFT)) {
		commit_draft(draft, board)
		return
	}

	if is_pan_mode_active() {
		return
	}

	cursor := rl.GetScreenToWorld2D(rl.GetMousePosition(), camera)

	if rl.IsMouseButtonPressed(.LEFT) {
		start_draft(draft, tool, cursor)
	} else if draft.is_active {
		extend_draft(draft, cursor, camera.zoom)
	}
}

start_draft :: proc(draft: ^Draft, tool: Tool, start: rl.Vector2) {
	draft.element = Element {
		shape        = new_shape(tool, start),
		color        = DEFAULT_STROKE_COLOR,
		stroke_width = DEFAULT_STROKE_WIDTH,
	}
	draft.is_active = true
}

new_shape :: proc(tool: Tool, start: rl.Vector2) -> Shape {
	shape: Shape
	switch tool {
	case .Freehand:
		freehand := Freehand{}
		append(&freehand.points, start)
		shape = freehand
	case .Rectangle:
		shape = Rectangle{start, start}
	case .Ellipse:
		shape = Ellipse{start, start}
	case .Line:
		shape = Line{start, start}
	case .Arrow:
		shape = Arrow{start, start}
	case .Select, .Text:
	}
	return shape
}

extend_draft :: proc(draft: ^Draft, cursor: rl.Vector2, zoom: f32) {
	switch &shape in draft.element.shape {
	case Freehand:
		extend_freehand(&shape, cursor, zoom)
	case Rectangle:
		shape.end = cursor
	case Ellipse:
		shape.end = cursor
	case Line:
		shape.end = cursor
	case Arrow:
		shape.end = cursor
	case Text:
	}
}

extend_freehand :: proc(freehand: ^Freehand, point: rl.Vector2, zoom: f32) {
	last_point := freehand.points[len(freehand.points) - 1]
	if rl.Vector2Distance(last_point, point) * zoom >= FREEHAND_MIN_SCREEN_STEP {
		append(&freehand.points, point)
	}
}

commit_draft :: proc(draft: ^Draft, board: ^Board) {
	if is_empty_shape(draft.element.shape) {
		destroy_element(&draft.element)
	} else {
		add_element(board, draft.element)
	}
	draft^ = {}
}

cancel_draft :: proc(draft: ^Draft) {
	destroy_element(&draft.element)
	draft^ = {}
}

draw_draft :: proc(draft: Draft) {
	if draft.is_active {
		draw_element(draft.element)
	}
}
