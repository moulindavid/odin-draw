package main

import "core:math"
import rl "vendor:raylib"

GRID_SPACING :: 20.0
GRID_MIN_SCREEN_SPACING :: 16.0
GRID_DOT_SCREEN_RADIUS :: 1.2
GRID_DOT_COLOR :: rl.Color{200, 200, 205, 255}

draw_dot_grid :: proc(camera: rl.Camera2D) {
	spacing := grid_spacing_for_zoom(camera.zoom)
	dot_radius := GRID_DOT_SCREEN_RADIUS / camera.zoom
	top_left, bottom_right := visible_world_bounds(camera)

	first_x := math.floor(top_left.x / spacing) * spacing
	first_y := math.floor(top_left.y / spacing) * spacing

	for x := first_x; x <= bottom_right.x; x += spacing {
		for y := first_y; y <= bottom_right.y; y += spacing {
			rl.DrawCircleV({x, y}, dot_radius, GRID_DOT_COLOR)
		}
	}
}

grid_spacing_for_zoom :: proc(zoom: f32) -> f32 {
	spacing: f32 = GRID_SPACING
	for spacing * zoom < GRID_MIN_SCREEN_SPACING {
		spacing *= 2
	}
	return spacing
}
