package main

import rl "vendor:raylib"

WINDOW_TITLE :: "excalidraw-local"
INITIAL_WIDTH :: 1280
INITIAL_HEIGHT :: 800
TARGET_FPS :: 60
BACKGROUND_COLOR :: rl.Color{250, 250, 250, 255}

main :: proc() {
	rl.SetConfigFlags({.WINDOW_RESIZABLE, .MSAA_4X_HINT, .VSYNC_HINT})
	rl.InitWindow(INITIAL_WIDTH, INITIAL_HEIGHT, WINDOW_TITLE)
	defer rl.CloseWindow()

	rl.SetTargetFPS(TARGET_FPS)
	rl.SetExitKey(.KEY_NULL)

	camera := make_camera()

	for !rl.WindowShouldClose() {
		update_camera(&camera)

		rl.BeginDrawing()
		rl.ClearBackground(BACKGROUND_COLOR)

		rl.BeginMode2D(camera)
		draw_dot_grid(camera)
		rl.EndMode2D()

		rl.EndDrawing()
	}
}
