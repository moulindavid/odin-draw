package main

import "core:math"
import rl "vendor:raylib"

ELLIPSE_SEGMENTS :: 64

rectangle_from_corners :: proc(a, b: rl.Vector2) -> rl.Rectangle {
	return rl.Rectangle {
		x = min(a.x, b.x),
		y = min(a.y, b.y),
		width = abs(a.x - b.x),
		height = abs(a.y - b.y),
	}
}

ellipse_points :: proc(corner_a, corner_b: rl.Vector2) -> (points: [ELLIPSE_SEGMENTS + 1]rl.Vector2) {
	center := (corner_a + corner_b) / 2
	radii := rl.Vector2{abs(corner_b.x - corner_a.x), abs(corner_b.y - corner_a.y)} / 2

	for &point, index in points {
		angle := f32(index) / ELLIPSE_SEGMENTS * math.TAU
		point = center + radii * rl.Vector2{math.cos(angle), math.sin(angle)}
	}
	return
}
