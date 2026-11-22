package main

import rl "vendor:raylib"

make_camera :: proc() -> rl.Camera2D {
	return rl.Camera2D{zoom = 1}
}

visible_world_bounds :: proc(camera: rl.Camera2D) -> (top_left, bottom_right: rl.Vector2) {
	screen_size := rl.Vector2{f32(rl.GetScreenWidth()), f32(rl.GetScreenHeight())}
	top_left = rl.GetScreenToWorld2D({0, 0}, camera)
	bottom_right = rl.GetScreenToWorld2D(screen_size, camera)
	return
}
