package main

import "core:fmt"
import "core:os"
import "core:path/filepath"
import "core:strings"
import rl "vendor:raylib"

UNTITLED_NAME :: "untitled"

File_Action :: enum {
	None,
	New,
	Open,
	Open_Dropped,
	Save,
	Save_As,
}

is_dialog_open :: proc(app: App) -> bool {
	return app.picker.is_open || app.prompt.is_open
}

update_file_dialogs :: proc(app: ^App) -> bool {
	if app.prompt.is_open {
		handle_prompt_choice(app, app.prompt.kind, update_prompt(&app.prompt))
		return true
	}

	if app.picker.is_open {
		result, path := update_file_picker(&app.picker)
		switch result {
		case .None:
		case .Confirmed:
			handle_picked_path(app, path)
		case .Cancelled:
			app.pending_action = .None
		}
		return true
	}

	if action := file_action_from_shortcuts(); action != .None {
		app.menu.is_open = false
		run_file_action(app, action)
		return true
	}

	action, consumed := update_menu(&app.menu)
	run_file_action(app, action)
	return consumed
}

file_action_from_shortcuts :: proc() -> File_Action {
	if !is_control_down() {
		return .None
	}
	if rl.IsKeyPressed(.N) {
		return .New
	}
	if rl.IsKeyPressed(.O) {
		return .Open
	}
	if rl.IsKeyPressed(.S) {
		return .Save_As if is_shift_down() else .Save
	}
	return .None
}

run_file_action :: proc(app: ^App, action: File_Action) {
	switch action {
	case .None:
	case .New, .Open, .Open_Dropped:
		request_board_change(app, action)
	case .Save:
		save_or_choose_file(app)
	case .Save_As:
		choose_save_file(app)
	}
}

request_board_change :: proc(app: ^App, action: File_Action) {
	if has_unsaved_changes(app^) {
		app.pending_action = action
		open_prompt(&app.prompt, .Unsaved_Changes)
		return
	}
	change_board(app, action)
}

change_board :: proc(app: ^App, action: File_Action) {
	#partial switch action {
	case .New:
		start_new_board(app)
	case .Open:
		choose_file_to_open(app)
	case .Open_Dropped:
		open_file(app, app.dropped_path)
	}
}

continue_pending_action :: proc(app: ^App) {
	action := app.pending_action
	app.pending_action = .None
	change_board(app, action)
}

save_or_choose_file :: proc(app: ^App) -> (saved: bool) {
	if app.file_path == "" {
		choose_save_file(app)
		return false
	}
	return save_to_path(app, app.file_path)
}

choose_file_to_open :: proc(app: ^App) {
	open_file_picker(&app.picker, .Open, current_directory(app^), "")
}

choose_save_file :: proc(app: ^App) {
	open_file_picker(&app.picker, .Save, current_directory(app^), suggested_file_name(app^))
}

handle_picked_path :: proc(app: ^App, path: string) {
	switch app.picker.mode {
	case .Open:
		close_file_picker(&app.picker)
		open_file(app, path)
	case .Save:
		if os.exists(path) && path != app.file_path {
			ask_to_overwrite(app, path)
			return
		}
		close_file_picker(&app.picker)
		if save_to_path(app, path) {
			continue_pending_action(app)
		}
	}
}

ask_to_overwrite :: proc(app: ^App, path: string) {
	delete(app.overwrite_path)
	app.overwrite_path = strings.clone(path)
	open_prompt(&app.prompt, .Overwrite)
}

handle_prompt_choice :: proc(app: ^App, kind: Prompt_Kind, choice: Prompt_Choice) {
	switch choice {
	case .None:
	case .Save:
		if save_or_choose_file(app) {
			continue_pending_action(app)
		}
	case .Discard:
		continue_pending_action(app)
	case .Replace:
		close_file_picker(&app.picker)
		if save_to_path(app, app.overwrite_path) {
			continue_pending_action(app)
		}
	case .Cancel:
		if kind == .Unsaved_Changes {
			app.pending_action = .None
		}
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
		delete(app.dropped_path)
		app.dropped_path = strings.clone(string(dropped.paths[0]))
		run_file_action(app, .Open_Dropped)
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

start_new_board :: proc(app: ^App) {
	set_elements(&app.board, {})
	delete(app.file_path)
	app.file_path = ""
	app.camera = make_camera()
	app.selection = {}
	reset_history(&app.history, app.board)
	app.saved_revision = app.board.revision
	show_status(&app.status, "New board")
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
