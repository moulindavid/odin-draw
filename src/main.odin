package main

import rl "vendor:raylib"

WINDOW_TITLE :: "excalidraw-local"
INITIAL_WIDTH :: 1280
INITIAL_HEIGHT :: 800
TARGET_FPS :: 60
BACKGROUND_COLOR :: rl.Color{250, 250, 250, 255}

App :: struct {
	camera: rl.Camera2D,
	board:  Board,
	tool:   Tool,
	draft:  Draft,
	editor: Text_Editor,
}

main :: proc() {
	rl.SetConfigFlags({.WINDOW_RESIZABLE, .MSAA_4X_HINT, .VSYNC_HINT})
	rl.InitWindow(INITIAL_WIDTH, INITIAL_HEIGHT, WINDOW_TITLE)
	defer rl.CloseWindow()

	rl.SetTargetFPS(TARGET_FPS)
	rl.SetExitKey(.KEY_NULL)

	app := App {
		camera = make_camera(),
		tool   = .Freehand,
	}
	defer destroy_board(&app.board)
	defer destroy_text_editor(&app.editor)

	for !rl.WindowShouldClose() {
		update_app(&app)
		draw_app(app)
		free_all(context.temp_allocator)
	}
}

update_app :: proc(app: ^App) {
	is_typing := app.editor.is_active
	update_camera(&app.camera, space_pans = !is_typing)

	if is_typing {
		update_text_editor(&app.editor, &app.board, app.camera)
		return
	}

	app.tool = tool_from_shortcuts(app.tool)
	app.tool = tool_from_toolbar_click(app.tool)

	if !app.draft.is_active && is_over_toolbar(rl.GetMousePosition()) {
		return
	}

	if app.tool == .Text && !app.draft.is_active {
		update_text_tool(&app.editor, app.camera)
	} else {
		update_drawing(app.tool, &app.draft, &app.board, app.camera)
	}
}

draw_app :: proc(app: App) {
	rl.BeginDrawing()
	defer rl.EndDrawing()

	rl.ClearBackground(BACKGROUND_COLOR)

	rl.BeginMode2D(app.camera)
	draw_dot_grid(app.camera)
	draw_board(app.board)
	draw_draft(app.draft)
	draw_text_editor(app.editor, app.camera.zoom)
	rl.EndMode2D()

	draw_toolbar(app.tool)
}
