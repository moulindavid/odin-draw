package main

import rl "vendor:raylib"

draw_board :: proc(board: Board) {
	for element in board.elements {
		draw_element(element)
	}
}

draw_element :: proc(element: Element) {
	switch shape in element.shape {
	case Freehand:
		draw_polyline(shape.points[:], element.stroke_width, element.color)
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
