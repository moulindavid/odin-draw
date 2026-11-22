package main

import "core:os"
import "core:path/filepath"
import "core:slice"
import "core:strings"
import rl "vendor:raylib"

PICKER_WIDTH :: 560
PICKER_HEIGHT :: 440
PICKER_PADDING :: 16
PICKER_TITLE_HEIGHT :: 28
PICKER_PATH_HEIGHT :: 24
PICKER_ROW_HEIGHT :: 26
PICKER_FIELD_HEIGHT :: 32
PICKER_BUTTON_WIDTH :: 96
PICKER_BUTTON_HEIGHT :: 32
PICKER_SCROLL_ROWS :: 3
BOARD_FILE_EXTENSION :: ".json"
PARENT_DIRECTORY :: ".."

Picker_Mode :: enum {
	Open,
	Save,
}

Picker_Result :: enum {
	None,
	Confirmed,
	Cancelled,
}

File_Entry :: struct {
	name:         string,
	is_directory: bool,
}

File_Picker :: struct {
	is_open:            bool,
	mode:               Picker_Mode,
	directory:          string,
	entries:            [dynamic]File_Entry,
	file_name:          strings.Builder,
	scroll:             int,
	last_clicked_entry: int,
	last_click_time:    f64,
}

open_file_picker :: proc(picker: ^File_Picker, mode: Picker_Mode, directory: string, suggested_name: string) {
	picker.is_open = true
	picker.mode = mode
	strings.builder_reset(&picker.file_name)
	strings.write_string(&picker.file_name, suggested_name)
	change_directory(picker, directory)
}

close_file_picker :: proc(picker: ^File_Picker) {
	picker.is_open = false
}

change_directory :: proc(picker: ^File_Picker, directory: string) {
	absolute, error := os.get_absolute_path(directory, context.allocator)
	if error != nil {
		return
	}
	delete(picker.directory)
	picker.directory = absolute
	picker.scroll = 0
	picker.last_clicked_entry = -1
	load_entries(picker)
}

load_entries :: proc(picker: ^File_Picker) {
	clear_entries(picker)
	if picker.directory != "/" {
		append(&picker.entries, File_Entry{strings.clone(PARENT_DIRECTORY), true})
	}

	infos, error := os.read_all_directory_by_path(picker.directory, context.temp_allocator)
	if error != nil {
		return
	}

	directories := make([dynamic]File_Entry, context.temp_allocator)
	files := make([dynamic]File_Entry, context.temp_allocator)
	for info in infos {
		if strings.has_prefix(info.name, ".") {
			continue
		}
		if is_directory_info(info) {
			append(&directories, File_Entry{strings.clone(info.name), true})
		} else if filepath.ext(info.name) == BOARD_FILE_EXTENSION {
			append(&files, File_Entry{strings.clone(info.name), false})
		}
	}

	slice.sort_by(directories[:], entry_name_less)
	slice.sort_by(files[:], entry_name_less)
	append(&picker.entries, ..directories[:])
	append(&picker.entries, ..files[:])
}

is_directory_info :: proc(info: os.File_Info) -> bool {
	return info.type == .Directory || (info.type == .Symlink && os.is_dir(info.fullpath))
}

entry_name_less :: proc(a, b: File_Entry) -> bool {
	return strings.to_lower(a.name, context.temp_allocator) < strings.to_lower(b.name, context.temp_allocator)
}

clear_entries :: proc(picker: ^File_Picker) {
	for entry in picker.entries {
		delete(entry.name)
	}
	clear(&picker.entries)
}

update_file_picker :: proc(picker: ^File_Picker) -> (result: Picker_Result, path: string) {
	if rl.IsKeyPressed(.ESCAPE) || is_clicked(picker_cancel_button_bounds()) {
		close_file_picker(picker)
		return .Cancelled, ""
	}

	type_into(&picker.file_name)
	scroll_entries(picker)

	if index, clicked := clicked_entry(picker^); clicked {
		if choose_entry(picker, index) {
			return confirm_picker(picker^)
		}
	}

	if is_enter_typed() || is_clicked(picker_confirm_button_bounds()) {
		return confirm_picker(picker^)
	}
	return .None, ""
}

scroll_entries :: proc(picker: ^File_Picker) {
	if !is_hovered(picker_list_bounds()) {
		return
	}
	wheel := rl.GetMouseWheelMove()
	if wheel == 0 {
		return
	}
	max_scroll := max(0, len(picker.entries) - visible_row_count())
	picker.scroll = clamp(picker.scroll - int(wheel) * PICKER_SCROLL_ROWS, 0, max_scroll)
}

clicked_entry :: proc(picker: File_Picker) -> (index: int, clicked: bool) {
	for row in 0 ..< visible_row_count() {
		entry_index := picker.scroll + row
		if entry_index >= len(picker.entries) {
			break
		}
		if is_clicked(picker_row_bounds(row)) {
			return entry_index, true
		}
	}
	return
}

choose_entry :: proc(picker: ^File_Picker, index: int) -> (wants_confirm: bool) {
	entry := picker.entries[index]
	if entry.is_directory {
		next_directory, _ := filepath.join({picker.directory, entry.name}, context.temp_allocator)
		change_directory(picker, next_directory)
		return false
	}

	now := rl.GetTime()
	is_double_click := picker.last_clicked_entry == index && now - picker.last_click_time <= DOUBLE_CLICK_SECONDS
	picker.last_clicked_entry = index
	picker.last_click_time = now

	strings.builder_reset(&picker.file_name)
	strings.write_string(&picker.file_name, entry.name)
	return is_double_click
}

confirm_picker :: proc(picker: File_Picker) -> (result: Picker_Result, path: string) {
	name := strings.trim_space(strings.to_string(picker.file_name))
	if name == "" {
		return .None, ""
	}

	path, _ = filepath.join({picker.directory, name}, context.temp_allocator)
	if picker.mode == .Save && filepath.ext(path) == "" {
		path = strings.concatenate({path, BOARD_FILE_EXTENSION}, context.temp_allocator)
	}
	if picker.mode == .Open && !os.is_file(path) {
		return .None, ""
	}
	return .Confirmed, path
}

picker_bounds :: proc() -> rl.Rectangle {
	return centered_rectangle(PICKER_WIDTH, PICKER_HEIGHT)
}

picker_list_bounds :: proc() -> rl.Rectangle {
	panel := picker_bounds()
	top := panel.y + PICKER_PADDING + PICKER_TITLE_HEIGHT + PICKER_PATH_HEIGHT
	bottom := picker_field_bounds().y - PICKER_PADDING
	return {panel.x + PICKER_PADDING, top, panel.width - 2 * PICKER_PADDING, bottom - top}
}

picker_row_bounds :: proc(row: int) -> rl.Rectangle {
	list := picker_list_bounds()
	return {list.x, list.y + f32(row) * PICKER_ROW_HEIGHT, list.width, PICKER_ROW_HEIGHT}
}

visible_row_count :: proc() -> int {
	return int(picker_list_bounds().height / PICKER_ROW_HEIGHT)
}

picker_field_bounds :: proc() -> rl.Rectangle {
	panel := picker_bounds()
	y := picker_confirm_button_bounds().y - PICKER_PADDING - PICKER_FIELD_HEIGHT
	return {panel.x + PICKER_PADDING, y, panel.width - 2 * PICKER_PADDING, PICKER_FIELD_HEIGHT}
}

picker_confirm_button_bounds :: proc() -> rl.Rectangle {
	panel := picker_bounds()
	x := panel.x + panel.width - PICKER_PADDING - PICKER_BUTTON_WIDTH
	y := panel.y + panel.height - PICKER_PADDING - PICKER_BUTTON_HEIGHT
	return {x, y, PICKER_BUTTON_WIDTH, PICKER_BUTTON_HEIGHT}
}

picker_cancel_button_bounds :: proc() -> rl.Rectangle {
	confirm := picker_confirm_button_bounds()
	return {confirm.x - PICKER_PADDING / 2 - PICKER_BUTTON_WIDTH, confirm.y, PICKER_BUTTON_WIDTH, PICKER_BUTTON_HEIGHT}
}

picker_title :: proc(mode: Picker_Mode) -> string {
	return "Open board" if mode == .Open else "Save board as"
}

picker_confirm_label :: proc(mode: Picker_Mode) -> string {
	return "Open" if mode == .Open else "Save"
}

draw_file_picker :: proc(picker: File_Picker) {
	if !picker.is_open {
		return
	}

	draw_overlay()
	panel := picker_bounds()
	draw_panel(panel)

	content_x := panel.x + PICKER_PADDING
	content_width := panel.width - 2 * PICKER_PADDING
	draw_label(picker_title(picker.mode), content_x, panel.y + PICKER_PADDING, UI_TEXT_COLOR)
	path_y := panel.y + PICKER_PADDING + PICKER_TITLE_HEIGHT
	draw_label(fit_label_from_end(picker.directory, content_width), content_x, path_y, UI_MUTED_TEXT_COLOR)

	draw_entries(picker)
	draw_file_name_field(picker)
	draw_button(picker_cancel_button_bounds(), "Cancel")
	draw_button(picker_confirm_button_bounds(), picker_confirm_label(picker.mode), is_primary = true)
}

draw_entries :: proc(picker: File_Picker) {
	list := picker_list_bounds()
	rl.DrawRectangleLinesEx(list, 1, UI_BORDER_COLOR)
	current_name := strings.to_string(picker.file_name)

	for row in 0 ..< visible_row_count() {
		entry_index := picker.scroll + row
		if entry_index >= len(picker.entries) {
			break
		}
		entry := picker.entries[entry_index]
		row_bounds := picker_row_bounds(row)

		if !entry.is_directory && entry.name == current_name {
			rl.DrawRectangleRec(row_bounds, UI_HIGHLIGHT_COLOR)
		} else if is_hovered(row_bounds) {
			rl.DrawRectangleRec(row_bounds, UI_HOVER_COLOR)
		}

		label := strings.concatenate({entry.name, "/"}, context.temp_allocator) if entry.is_directory else entry.name
		color := UI_MUTED_TEXT_COLOR if entry.is_directory else UI_TEXT_COLOR
		draw_label(label, row_bounds.x + 8, row_bounds.y + (PICKER_ROW_HEIGHT - UI_FONT_SIZE) / 2, color)
	}
}

draw_file_name_field :: proc(picker: File_Picker) {
	field := picker_field_bounds()
	draw_rounded(field, UI_PANEL_COLOR)
	draw_rounded_border(field, ACCENT_COLOR)

	name := strings.to_string(picker.file_name)
	text_x := field.x + 8
	text_y := field.y + (PICKER_FIELD_HEIGHT - UI_FONT_SIZE) / 2
	draw_label(name, text_x, text_y, UI_TEXT_COLOR)

	if is_caret_visible() {
		caret_x := text_x + f32(measure_label(name)) + 2
		rl.DrawLineEx({caret_x, text_y}, {caret_x, text_y + UI_FONT_SIZE}, 1.5, UI_TEXT_COLOR)
	}
}

destroy_file_picker :: proc(picker: ^File_Picker) {
	clear_entries(picker)
	delete(picker.entries)
	delete(picker.directory)
	strings.builder_destroy(&picker.file_name)
}
