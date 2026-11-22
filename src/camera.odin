package main

import "core:math"
import rl "vendor:raylib"

MIN_ZOOM :: 0.1
MAX_ZOOM :: 10.0
ZOOM_SPEED :: 0.15

make_camera :: proc() -> rl.Camera2D {
	return rl.Camera2D{zoom = 1}
}

update_camera :: proc(camera: ^rl.Camera2D) {
	zoom_toward_cursor(camera)
	pan_with_mouse(camera)
	show_pan_cursor(is_pan_mode_active())
}

is_pan_mode_active :: proc() -> bool {
	return rl.IsKeyDown(.SPACE) || rl.IsMouseButtonDown(.MIDDLE)
}

is_panning :: proc() -> bool {
	space_drag := rl.IsKeyDown(.SPACE) && rl.IsMouseButtonDown(.LEFT)
	return space_drag || rl.IsMouseButtonDown(.MIDDLE)
}

pan_with_mouse :: proc(camera: ^rl.Camera2D) {
	if !is_panning() {
		return
	}
	camera.target -= rl.GetMouseDelta() / camera.zoom
}

show_pan_cursor :: proc(active: bool) {
	rl.SetMouseCursor(active ? .RESIZE_ALL : .DEFAULT)
}

zoom_toward_cursor :: proc(camera: ^rl.Camera2D) {
	wheel := rl.GetMouseWheelMove()
	if wheel == 0 {
		return
	}

	cursor := rl.GetMousePosition()
	camera.target = rl.GetScreenToWorld2D(cursor, camera^)
	camera.offset = cursor
	camera.zoom = clamp(camera.zoom * math.exp(wheel * ZOOM_SPEED), MIN_ZOOM, MAX_ZOOM)
}

visible_world_bounds :: proc(camera: rl.Camera2D) -> (top_left, bottom_right: rl.Vector2) {
	screen_size := rl.Vector2{f32(rl.GetScreenWidth()), f32(rl.GetScreenHeight())}
	top_left = rl.GetScreenToWorld2D({0, 0}, camera)
	bottom_right = rl.GetScreenToWorld2D(screen_size, camera)
	return
}
