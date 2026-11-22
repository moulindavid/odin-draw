package main

import "core:os"
import rl "vendor:raylib"

WINDOW_TITLE :: "excalidraw-local"
INITIAL_WIDTH :: 1280
INITIAL_HEIGHT :: 800
TARGET_FPS :: 60
BACKGROUND_COLOR :: rl.Color{250, 250, 250, 255}
ACCENT_COLOR :: rl.Color{120, 110, 255, 255}

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
	picker:         File_Picker,
	prompt:         Prompt,
	overwrite_path: string,
	dropped_path:   string,
	pending_action: File_Action,
	menu:           Menu,
}

main :: proc() {
	rl.SetConfigFlags({.WINDOW_RESIZABLE, .MSAA_4X_HINT, .VSYNC_HINT})
	rl.InitWindow(INITIAL_WIDTH, INITIAL_HEIGHT, WINDOW_TITLE)
	defer rl.CloseWindow()

	rl.SetTargetFPS(TARGET_FPS)
	rl.SetExitKey(.KEY_NULL)

	app := make_app(file_path_from_arguments())
	defer destroy_app(&app)

	for !rl.WindowShouldClose() {
		update_app(&app)
		draw_app(app)
		free_all(context.temp_allocator)
	}
}

make_app :: proc(file_path: string) -> App {
	app := App {
		camera    = make_camera(),
		tool      = .Select,
		file_path = file_path,
	}
	open_initial_file(&app)
	init_history(&app.history, app.board)
	app.saved_revision = app.board.revision
	return app
}

destroy_app :: proc(app: ^App) {
	destroy_board(&app.board)
	destroy_text_editor(&app.editor)
	destroy_history(&app.history)
	destroy_status(&app.status)
	destroy_file_picker(&app.picker)
	delete(app.file_path)
	delete(app.window_title)
	delete(app.overwrite_path)
	delete(app.dropped_path)
}

file_path_from_arguments :: proc() -> string {
	return absolute_path(os.args[1]) if len(os.args) > 1 else ""
}

update_app :: proc(app: ^App) {
	update_input(app)
	if !is_interacting(app^) && !is_dialog_open(app^) {
		record_change(&app.history, app.board)
		open_dropped_file(app)
	}
	update_window_title(app)
}

is_interacting :: proc(app: App) -> bool {
	return app.draft.is_active || app.selection.is_dragging || app.editor.is_active
}

update_input :: proc(app: ^App) {
	is_typing := app.editor.is_active
	if !is_dialog_open(app^) {
		update_camera(&app.camera, space_pans = !is_typing)
	}

	if is_typing {
		update_text_editor(&app.editor, &app.board, app.camera)
		if rl.IsKeyPressed(.ESCAPE) {
			app.tool = .Select
		}
		return
	}

	is_busy := app.draft.is_active || app.selection.is_dragging
	if !is_busy && update_file_dialogs(app) {
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
	draw_menu(app.menu)
	draw_status(app.status)
	draw_file_picker(app.picker)
	draw_prompt(app.prompt)
}
