package main

import "core:math"
import rl "vendor:raylib"

ELLIPSE_SEGMENTS :: 64
ARROW_HEAD_LENGTH :: 16.0
ARROW_HEAD_ANGLE :: 25 * math.RAD_PER_DEG

draw_board :: proc(board: Board) {
	for element in board.elements {
		draw_element(element)
	}
}

draw_element :: proc(element: Element) {
	switch shape in element.shape {
	case Freehand:
		draw_polyline(shape.points[:], element.stroke_width, element.color)
	case Rectangle:
		rl.DrawRectangleLinesEx(rectangle_from_corners(shape.start, shape.end), element.stroke_width, element.color)
	case Ellipse:
		draw_ellipse_outline(shape.start, shape.end, element.stroke_width, element.color)
	case Line:
		draw_polyline([]rl.Vector2{shape.start, shape.end}, element.stroke_width, element.color)
	case Arrow:
		draw_arrow(shape.start, shape.end, element.stroke_width, element.color)
	}
}

draw_arrow :: proc(start, end: rl.Vector2, width: f32, color: rl.Color) {
	draw_polyline([]rl.Vector2{start, end}, width, color)

	back_direction := rl.Vector2Normalize(start - end)
	head_length := min(ARROW_HEAD_LENGTH, rl.Vector2Distance(start, end) / 2)
	left_tip := end + rl.Vector2Rotate(back_direction, ARROW_HEAD_ANGLE) * head_length
	right_tip := end + rl.Vector2Rotate(back_direction, -ARROW_HEAD_ANGLE) * head_length
	draw_polyline([]rl.Vector2{left_tip, end, right_tip}, width, color)
}

draw_ellipse_outline :: proc(corner_a, corner_b: rl.Vector2, width: f32, color: rl.Color) {
	center := (corner_a + corner_b) / 2
	radii := rl.Vector2{abs(corner_b.x - corner_a.x), abs(corner_b.y - corner_a.y)} / 2

	points: [ELLIPSE_SEGMENTS + 1]rl.Vector2
	for &point, index in points {
		angle := f32(index) / ELLIPSE_SEGMENTS * math.TAU
		point = center + radii * rl.Vector2{math.cos(angle), math.sin(angle)}
	}
	draw_polyline(points[:], width, color)
}

rectangle_from_corners :: proc(a, b: rl.Vector2) -> rl.Rectangle {
	return rl.Rectangle {
		x = min(a.x, b.x),
		y = min(a.y, b.y),
		width = abs(a.x - b.x),
		height = abs(a.y - b.y),
	}
}

draw_polyline :: proc(points: []rl.Vector2, width: f32, color: rl.Color) {
	radius := width / 2
	for point, index in points {
		rl.DrawCircleV(point, radius, color)
		if index > 0 {
			rl.DrawLineEx(points[index - 1], point, width, color)
		}
	}
}
