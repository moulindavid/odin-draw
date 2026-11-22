package main

import "core:fmt"
import "core:os"
import "core:path/filepath"
import "core:strings"
import rl "vendor:raylib"

update_file_keys :: proc(app: ^App) {
	if is_control_down() && rl.IsKeyPressed(.S) {
		save_to_current_file(app)
	}
}

save_to_current_file :: proc(app: ^App) {
	if save_board(app.board, app.file_path) {
		app.saved_revision = app.board.revision
		show_status(&app.status, "Saved %s", app.file_path)
	} else {
		show_status(&app.status, "Could not save %s", app.file_path)
	}
}

open_initial_file :: proc(app: ^App) {
	if !os.exists(app.file_path) {
		return
	}
	if load_board(&app.board, app.file_path) {
		show_status(&app.status, "Opened %s", app.file_path)
	} else {
		show_status(&app.status, "Could not open %s", app.file_path)
	}
}

open_dropped_file :: proc(app: ^App) {
	if !rl.IsFileDropped() {
		return
	}
	dropped := rl.LoadDroppedFiles()
	defer rl.UnloadDroppedFiles(dropped)

	if dropped.count > 0 {
		open_file(app, string(dropped.paths[0]))
	}
}

open_file :: proc(app: ^App, path: string) {
	if !load_board(&app.board, path) {
		show_status(&app.status, "Could not open %s", path)
		return
	}
	delete(app.file_path)
	app.file_path = strings.clone(path)
	app.selection = {}
	reset_history(&app.history, app.board)
	app.saved_revision = app.board.revision
	show_status(&app.status, "Opened %s", app.file_path)
}

has_unsaved_changes :: proc(app: App) -> bool {
	return app.board.revision != app.saved_revision
}

update_window_title :: proc(app: ^App) {
	unsaved_marker := "*" if has_unsaved_changes(app^) else ""
	title := fmt.tprintf("%s%s - %s", unsaved_marker, filepath.base(app.file_path), WINDOW_TITLE)
	if title == app.window_title {
		return
	}
	delete(app.window_title)
	app.window_title = strings.clone(title)
	rl.SetWindowTitle(strings.clone_to_cstring(title, context.temp_allocator))
}
