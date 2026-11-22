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

rectangle_outline :: proc(corner_a, corner_b: rl.Vector2) -> [5]rl.Vector2 {
	r := rectangle_from_corners(corner_a, corner_b)
	return {{r.x, r.y}, {r.x + r.width, r.y}, {r.x + r.width, r.y + r.height}, {r.x, r.y + r.height}, {r.x, r.y}}
}

expand_rectangle :: proc(rectangle: rl.Rectangle, amount: f32) -> rl.Rectangle {
	return rl.Rectangle {
		x = rectangle.x - amount,
		y = rectangle.y - amount,
		width = rectangle.width + 2 * amount,
		height = rectangle.height + 2 * amount,
	}
}

points_bounds :: proc(points: []rl.Vector2) -> rl.Rectangle {
	top_left := points[0]
	bottom_right := points[0]
	for point in points {
		top_left = {min(top_left.x, point.x), min(top_left.y, point.y)}
		bottom_right = {max(bottom_right.x, point.x), max(bottom_right.y, point.y)}
	}
	return rectangle_from_corners(top_left, bottom_right)
}

distance_to_segment :: proc(point, segment_start, segment_end: rl.Vector2) -> f32 {
	segment := segment_end - segment_start
	length_squared := rl.Vector2LengthSqr(segment)
	if length_squared == 0 {
		return rl.Vector2Distance(point, segment_start)
	}
	progress := clamp(rl.Vector2DotProduct(point - segment_start, segment) / length_squared, 0, 1)
	return rl.Vector2Distance(point, segment_start + segment * progress)
}

is_near_polyline :: proc(points: []rl.Vector2, point: rl.Vector2, reach: f32) -> bool {
	if len(points) == 1 {
		return rl.Vector2Distance(points[0], point) <= reach
	}
	for index in 1 ..< len(points) {
		if distance_to_segment(point, points[index - 1], points[index]) <= reach {
			return true
		}
	}
	return false
}
