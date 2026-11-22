package main

import rl "vendor:raylib"

FREEHAND_MIN_SCREEN_STEP :: 2.0

Freehand_Tool :: struct {
	stroke:     Element,
	is_drawing: bool,
}

update_freehand_tool :: proc(tool: ^Freehand_Tool, board: ^Board, camera: rl.Camera2D) {
	if tool.is_drawing && (is_pan_mode_active() || !rl.IsMouseButtonDown(.LEFT)) {
		finish_stroke(tool, board)
		return
	}

	if is_pan_mode_active() {
		return
	}

	cursor := rl.GetScreenToWorld2D(rl.GetMousePosition(), camera)

	if rl.IsMouseButtonPressed(.LEFT) {
		start_stroke(tool, cursor)
	} else if tool.is_drawing {
		extend_stroke(tool, cursor, camera.zoom)
	}
}

start_stroke :: proc(tool: ^Freehand_Tool, start: rl.Vector2) {
	freehand := Freehand{}
	append(&freehand.points, start)
	tool.stroke = Element {
		shape        = freehand,
		color        = DEFAULT_STROKE_COLOR,
		stroke_width = DEFAULT_STROKE_WIDTH,
	}
	tool.is_drawing = true
}

extend_stroke :: proc(tool: ^Freehand_Tool, point: rl.Vector2, zoom: f32) {
	freehand := &tool.stroke.shape.(Freehand)
	last_point := freehand.points[len(freehand.points) - 1]
	if rl.Vector2Distance(last_point, point) * zoom >= FREEHAND_MIN_SCREEN_STEP {
		append(&freehand.points, point)
	}
}

finish_stroke :: proc(tool: ^Freehand_Tool, board: ^Board) {
	add_element(board, tool.stroke)
	tool.stroke = {}
	tool.is_drawing = false
}

draw_freehand_tool :: proc(tool: Freehand_Tool) {
	if tool.is_drawing {
		draw_element(tool.stroke)
	}
}
