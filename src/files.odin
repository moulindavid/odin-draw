package main

import "core:fmt"
import "core:os"
import "core:path/filepath"
import "core:strings"
import rl "vendor:raylib"

UNTITLED_NAME :: "untitled"

File_Action :: enum {
	None,
	Save,
	Save_As,
}

is_dialog_open :: proc(app: App) -> bool {
	return app.picker.is_open
}

update_file_dialogs :: proc(app: ^App) -> (consumed: bool) {
	if app.picker.is_open {
		result, path := update_file_picker(&app.picker)
		if result == .Confirmed {
			handle_picked_path(app, path)
		}
		return true
	}

	action := file_action_from_shortcuts()
	run_file_action(app, action)
	return action != .None
}

file_action_from_shortcuts :: proc() -> File_Action {
	if !is_control_down() || !rl.IsKeyPressed(.S) {
		return .None
	}
	return .Save_As if is_shift_down() else .Save
}

run_file_action :: proc(app: ^App, action: File_Action) {
	switch action {
	case .None:
	case .Save:
		save_or_choose_file(app)
	case .Save_As:
		choose_save_file(app)
	}
}

save_or_choose_file :: proc(app: ^App) -> (saved: bool) {
	if app.file_path == "" {
		choose_save_file(app)
		return false
	}
	return save_to_path(app, app.file_path)
}

choose_save_file :: proc(app: ^App) {
	open_file_picker(&app.picker, .Save, current_directory(app^), suggested_file_name(app^))
}

handle_picked_path :: proc(app: ^App, path: string) {
	close_file_picker(&app.picker)
	switch app.picker.mode {
	case .Open:
		open_file(app, path)
	case .Save:
		save_to_path(app, path)
	}
}

save_to_path :: proc(app: ^App, path: string) -> bool {
	if !save_board(app.board, path) {
		show_status(&app.status, "Could not save %s", filepath.base(path))
		return false
	}
	set_file_path(app, path)
	app.saved_revision = app.board.revision
	show_status(&app.status, "Saved %s", filepath.base(app.file_path))
	return true
}

open_initial_file :: proc(app: ^App) {
	if app.file_path == "" || !os.exists(app.file_path) {
		return
	}
	if load_board(&app.board, app.file_path) {
		show_status(&app.status, "Opened %s", filepath.base(app.file_path))
	} else {
		show_status(&app.status, "Could not open %s", filepath.base(app.file_path))
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
		show_status(&app.status, "Could not open %s", filepath.base(path))
		return
	}
	set_file_path(app, path)
	app.selection = {}
	reset_history(&app.history, app.board)
	app.saved_revision = app.board.revision
	show_status(&app.status, "Opened %s", filepath.base(app.file_path))
}

set_file_path :: proc(app: ^App, path: string) {
	absolute := absolute_path(path)
	delete(app.file_path)
	app.file_path = absolute
}

absolute_path :: proc(path: string) -> string {
	absolute, error := os.get_absolute_path(path, context.allocator)
	if error != nil {
		return strings.clone(path)
	}
	return absolute
}

current_directory :: proc(app: App) -> string {
	return "." if app.file_path == "" else filepath.dir(app.file_path)
}

suggested_file_name :: proc(app: App) -> string {
	if app.file_path == "" {
		return UNTITLED_NAME + BOARD_FILE_EXTENSION
	}
	return filepath.base(app.file_path)
}

has_unsaved_changes :: proc(app: App) -> bool {
	return app.board.revision != app.saved_revision
}

update_window_title :: proc(app: ^App) {
	unsaved_marker := "*" if has_unsaved_changes(app^) else ""
	name := UNTITLED_NAME if app.file_path == "" else filepath.base(app.file_path)
	title := fmt.tprintf("%s%s - %s", unsaved_marker, name, WINDOW_TITLE)
	if title == app.window_title {
		return
	}
	delete(app.window_title)
	app.window_title = strings.clone(title)
	rl.SetWindowTitle(strings.clone_to_cstring(title, context.temp_allocator))
}
