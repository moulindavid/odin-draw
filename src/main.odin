package main

import "core:os"
import "core:strings"
import rl "vendor:raylib"

WINDOW_TITLE :: "excalidraw-local"
INITIAL_WIDTH :: 1280
INITIAL_HEIGHT :: 800
TARGET_FPS :: 60
BACKGROUND_COLOR :: rl.Color{250, 250, 250, 255}
ACCENT_COLOR :: rl.Color{120, 110, 255, 255}
DEFAULT_FILE_PATH :: "untitled.json"

App :: struct {
	camera:         rl.Camera2D,
	board:          Board,
	tool:           Tool,
	draft:          Draft,
	editor:         Text_Editor,
	selection:      Selection,
	history:        History,
	file_path:      string,
	saved_revision: int,
	window_title:   string,
	status:         Status,
}

main :: proc() {
	rl.SetConfigFlags({.WINDOW_RESIZABLE, .MSAA_4X_HINT, .VSYNC_HINT})
	rl.InitWindow(INITIAL_WIDTH, INITIAL_HEIGHT, WINDOW_TITLE)
	defer rl.CloseWindow()

	rl.SetTargetFPS(TARGET_FPS)
	rl.SetExitKey(.KEY_NULL)

	app := App {
		camera    = make_camera(),
		tool      = .Select,
		file_path = strings.clone(file_path_from_arguments()),
	}
	defer destroy_board(&app.board)
	defer destroy_text_editor(&app.editor)
	defer destroy_history(&app.history)
	defer destroy_status(&app.status)
	defer delete(app.file_path)
	defer delete(app.window_title)
	open_initial_file(&app)
	init_history(&app.history, app.board)
	app.saved_revision = app.board.revision

	for !rl.WindowShouldClose() {
		update_app(&app)
		draw_app(app)
		free_all(context.temp_allocator)
	}
}

file_path_from_arguments :: proc() -> string {
	return os.args[1] if len(os.args) > 1 else DEFAULT_FILE_PATH
}

update_app :: proc(app: ^App) {
	update_input(app)
	if !is_interacting(app^) {
		record_change(&app.history, app.board)
		update_file_keys(app)
		open_dropped_file(app)
	}
	update_window_title(app)
}

is_interacting :: proc(app: App) -> bool {
	return app.draft.is_active || app.selection.is_dragging || app.editor.is_active
}

update_input :: proc(app: ^App) {
	is_typing := app.editor.is_active
	update_camera(&app.camera, space_pans = !is_typing)

	if is_typing {
		update_text_editor(&app.editor, &app.board, app.camera)
		if rl.IsKeyPressed(.ESCAPE) {
			app.tool = .Select
		}
		return
	}

	previous_tool := app.tool
	app.tool = tool_from_shortcuts(app.tool)
	app.tool = tool_from_toolbar_click(app.tool)
	if app.tool != previous_tool {
		app.selection = {}
	}

	if app.draft.is_active {
		update_drawing(app.tool, &app.draft, &app.board, app.camera)
		return
	}

	if !app.selection.is_dragging && update_history_keys(&app.history, &app.board) {
		app.selection = {}
		return
	}

	update_selection_keys(&app.selection, &app.board)

	if !app.selection.is_dragging && is_over_toolbar(rl.GetMousePosition()) {
		return
	}

	#partial switch app.tool {
	case .Select:
		update_select_tool(&app.selection, &app.editor, &app.board, app.camera)
	case .Text:
		update_text_tool(&app.editor, &app.board, app.camera)
	case:
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
	draw_selection(app.selection, app.board, app.camera.zoom)
	draw_draft(app.draft)
	draw_text_editor(app.editor, app.camera.zoom)
	rl.EndMode2D()

	draw_toolbar(app.tool)
	draw_status(app.status)
}
