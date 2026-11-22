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
		draw_freehand(shape, element.color, element.stroke_width)
	}
}

draw_freehand :: proc(freehand: Freehand, color: rl.Color, width: f32) {
	radius := width / 2
	for point, index in freehand.points {
		rl.DrawCircleV(point, radius, color)
		if index > 0 {
			rl.DrawLineEx(freehand.points[index - 1], point, width, color)
		}
	}
}
