package main

import "core:strings"
import rl "vendor:raylib"

TEXT_EDITOR_PADDING :: 4.0
TEXT_EDITOR_MIN_WIDTH :: 20.0
TEXT_EDITOR_BORDER_SCREEN_WIDTH :: 1.0
TEXT_CARET_SCREEN_WIDTH :: 1.5
TEXT_CARET_BLINK_SECONDS :: 0.5

Text_Editor :: struct {
	is_active:      bool,
	position:       rl.Vector2,
	color:          rl.Color,
	buffer:         strings.Builder,
	original_index: Maybe(int),
}

update_text_tool :: proc(editor: ^Text_Editor, board: ^Board, camera: rl.Camera2D) {
	if !rl.IsMouseButtonPressed(.LEFT) || is_pan_mode_active() {
		return
	}
	cursor := rl.GetScreenToWorld2D(rl.GetMousePosition(), camera)
	if index, found := text_element_at(board^, cursor); found {
		start_editing_existing_text(editor, board, index)
	} else {
		start_text_editing(editor, cursor - {0, TEXT_FONT_SIZE / 2})
	}
}

start_text_editing :: proc(editor: ^Text_Editor, position: rl.Vector2) {
	editor.is_active = true
	editor.position = position
	editor.color = DEFAULT_STROKE_COLOR
	editor.original_index = nil
	strings.builder_reset(&editor.buffer)
}

start_editing_existing_text :: proc(editor: ^Text_Editor, board: ^Board, index: int) {
	element := take_element(board, index)
	defer destroy_element(&element)

	text := element.shape.(Text)
	start_text_editing(editor, text.position)
	editor.color = element.color
	editor.original_index = index
	strings.write_string(&editor.buffer, text.content)
}

update_text_editor :: proc(editor: ^Text_Editor, board: ^Board, camera: rl.Camera2D) {
	if rl.IsKeyPressed(.ESCAPE) || is_click_outside_editor(editor^, camera) {
		finish_text_editing(editor, board)
		return
	}

	type_characters(editor)

	if is_key_typed(.ENTER) || is_key_typed(.KP_ENTER) {
		strings.write_byte(&editor.buffer, '\n')
	}
	if is_key_typed(.BACKSPACE) && strings.builder_len(editor.buffer) > 0 {
		strings.pop_rune(&editor.buffer)
	}
}

type_characters :: proc(editor: ^Text_Editor) {
	for character := rl.GetCharPressed(); character != 0; character = rl.GetCharPressed() {
		strings.write_rune(&editor.buffer, character)
	}
}

is_key_typed :: proc(key: rl.KeyboardKey) -> bool {
	return rl.IsKeyPressed(key) || rl.IsKeyPressedRepeat(key)
}

is_click_outside_editor :: proc(editor: Text_Editor, camera: rl.Camera2D) -> bool {
	if !rl.IsMouseButtonPressed(.LEFT) {
		return false
	}
	cursor := rl.GetScreenToWorld2D(rl.GetMousePosition(), camera)
	return !rl.CheckCollisionPointRec(cursor, text_editor_bounds(editor))
}

finish_text_editing :: proc(editor: ^Text_Editor, board: ^Board) {
	content := strings.trim_right_space(strings.to_string(editor.buffer))
	if strings.trim_space(content) != "" {
		text := Text {
			position  = editor.position,
			content   = strings.clone(content),
			font_size = TEXT_FONT_SIZE,
		}
		element := Element{shape = text, color = editor.color}
		if index, was_existing := editor.original_index.?; was_existing {
			insert_element(board, index, element)
		} else {
			add_element(board, element)
		}
	}
	editor.is_active = false
}

text_editor_bounds :: proc(editor: Text_Editor) -> rl.Rectangle {
	size := measure_text_block(strings.to_string(editor.buffer), TEXT_FONT_SIZE)
	return rl.Rectangle {
		x = editor.position.x - TEXT_EDITOR_PADDING,
		y = editor.position.y - TEXT_EDITOR_PADDING,
		width = max(size.x, TEXT_EDITOR_MIN_WIDTH) + 2 * TEXT_EDITOR_PADDING,
		height = size.y + 2 * TEXT_EDITOR_PADDING,
	}
}

draw_text_editor :: proc(editor: Text_Editor, zoom: f32) {
	if !editor.is_active {
		return
	}

	content := strings.to_string(editor.buffer)
	rl.DrawRectangleLinesEx(text_editor_bounds(editor), TEXT_EDITOR_BORDER_SCREEN_WIDTH / zoom, ACCENT_COLOR)
	draw_text_block(content, editor.position, TEXT_FONT_SIZE, editor.color)

	if is_caret_visible() {
		caret := caret_position(content, editor.position, TEXT_FONT_SIZE)
		rl.DrawLineEx(caret, caret + {0, TEXT_FONT_SIZE}, TEXT_CARET_SCREEN_WIDTH / zoom, editor.color)
	}
}

caret_position :: proc(content: string, position: rl.Vector2, font_size: f32) -> rl.Vector2 {
	lines := text_lines(content)
	last_index := len(lines) - 1
	x := measure_text_line(lines[last_index], font_size) + text_spacing(font_size)
	y := f32(last_index) * text_line_height(font_size)
	return position + {x, y}
}

is_caret_visible :: proc() -> bool {
	return int(rl.GetTime() / TEXT_CARET_BLINK_SECONDS) % 2 == 0
}

destroy_text_editor :: proc(editor: ^Text_Editor) {
	strings.builder_destroy(&editor.buffer)
}
