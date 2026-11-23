package main

import "core:strings"
import "core:unicode"
import "core:unicode/utf8"
import rl "vendor:raylib"

TEXT_FIELD_PADDING :: 8.0
TEXT_FIELD_CARET_WIDTH :: 1.5

Text_Field :: struct {
	buffer:          strings.Builder,
	caret:           int,
	anchor:          int,
	is_dragging:     bool,
	click_count:     int,
	last_click_time: f64,
}

field_text :: proc(field: Text_Field) -> string {
	return strings.to_string(field.buffer)
}

set_field_text :: proc(field: ^Text_Field, text: string) {
	strings.builder_reset(&field.buffer)
	strings.write_string(&field.buffer, text)
	field.caret = len(text)
	field.anchor = field.caret
}

select_field_range :: proc(field: ^Text_Field, start, end: int) {
	field.anchor = start
	field.caret = end
}

field_selection :: proc(field: Text_Field) -> (start, end: int) {
	return min(field.anchor, field.caret), max(field.anchor, field.caret)
}

has_field_selection :: proc(field: Text_Field) -> bool {
	return field.anchor != field.caret
}

update_text_field :: proc(field: ^Text_Field, bounds: rl.Rectangle) {
	update_field_mouse(field, bounds)
	update_field_navigation(field)
	update_field_editing(field)
}

update_field_mouse :: proc(field: ^Text_Field, bounds: rl.Rectangle) {
	if is_clicked(bounds) {
		index := field_index_at(field^, rl.GetMousePosition().x - bounds.x - TEXT_FIELD_PADDING)
		switch count_field_click(field) {
		case 1:
			move_field_caret(field, index, extend = is_shift_down())
			field.is_dragging = true
		case 2:
			select_word_at(field, index)
		case:
			select_field_range(field, 0, len(field_text(field^)))
		}
	} else if field.is_dragging && rl.IsMouseButtonDown(.LEFT) {
		field.caret = field_index_at(field^, rl.GetMousePosition().x - bounds.x - TEXT_FIELD_PADDING)
	} else {
		field.is_dragging = false
	}
}

count_field_click :: proc(field: ^Text_Field) -> int {
	now := rl.GetTime()
	is_repeated := now - field.last_click_time <= DOUBLE_CLICK_SECONDS
	field.click_count = field.click_count + 1 if is_repeated else 1
	field.last_click_time = now
	return field.click_count
}

select_word_at :: proc(field: ^Text_Field, index: int) {
	text := field_text(field^)
	if len(text) == 0 {
		return
	}
	clicked := index if index < len(text) else previous_rune_index(text, index)
	is_word := is_word_character(rune_at(text, clicked))

	start := clicked
	for start > 0 && is_word_character(rune_at(text, previous_rune_index(text, start))) == is_word {
		start = previous_rune_index(text, start)
	}
	end := next_rune_index(text, clicked)
	for end < len(text) && is_word_character(rune_at(text, end)) == is_word {
		end = next_rune_index(text, end)
	}
	select_field_range(field, start, end)
}

rune_at :: proc(text: string, index: int) -> rune {
	character, _ := utf8.decode_rune_in_string(text[index:])
	return character
}

is_word_character :: proc(character: rune) -> bool {
	return unicode.is_letter(character) || unicode.is_digit(character) || character == '_'
}

update_field_navigation :: proc(field: ^Text_Field) {
	text := field_text(field^)
	extend := is_shift_down()

	if is_control_down() && rl.IsKeyPressed(.A) {
		select_field_range(field, 0, len(text))
	} else if is_key_typed(.HOME) {
		move_field_caret(field, 0, extend)
	} else if is_key_typed(.END) {
		move_field_caret(field, len(text), extend)
	} else if is_key_typed(.LEFT) {
		start, _ := field_selection(field^)
		target := start if has_field_selection(field^) && !extend else previous_rune_index(text, field.caret)
		move_field_caret(field, target, extend)
	} else if is_key_typed(.RIGHT) {
		_, end := field_selection(field^)
		target := end if has_field_selection(field^) && !extend else next_rune_index(text, field.caret)
		move_field_caret(field, target, extend)
	}
}

update_field_editing :: proc(field: ^Text_Field) {
	text := field_text(field^)

	if is_key_typed(.BACKSPACE) {
		if !has_field_selection(field^) {
			field.anchor = previous_rune_index(text, field.caret)
		}
		replace_field_selection(field, "")
	} else if is_key_typed(.DELETE) {
		if !has_field_selection(field^) {
			field.anchor = next_rune_index(text, field.caret)
		}
		replace_field_selection(field, "")
	}

	for character := rl.GetCharPressed(); character != 0; character = rl.GetCharPressed() {
		encoded, size := utf8.encode_rune(character)
		replace_field_selection(field, string(encoded[:size]))
	}
}

move_field_caret :: proc(field: ^Text_Field, index: int, extend: bool) {
	field.caret = index
	if !extend {
		field.anchor = index
	}
}

replace_field_selection :: proc(field: ^Text_Field, replacement: string) {
	start, end := field_selection(field^)
	text := strings.clone(field_text(field^), context.temp_allocator)
	strings.builder_reset(&field.buffer)
	strings.write_string(&field.buffer, text[:start])
	strings.write_string(&field.buffer, replacement)
	strings.write_string(&field.buffer, text[end:])
	field.caret = start + len(replacement)
	field.anchor = field.caret
}

previous_rune_index :: proc(text: string, index: int) -> int {
	if index <= 0 {
		return 0
	}
	_, size := utf8.decode_last_rune_in_string(text[:index])
	return index - size
}

next_rune_index :: proc(text: string, index: int) -> int {
	if index >= len(text) {
		return len(text)
	}
	_, size := utf8.decode_rune_in_string(text[index:])
	return index + size
}

field_index_at :: proc(field: Text_Field, x: f32) -> int {
	text := field_text(field)
	closest := 0
	closest_distance := abs(x)
	for index := 0; index < len(text); {
		index = next_rune_index(text, index)
		distance := abs(x - f32(measure_label(text[:index])))
		if distance < closest_distance {
			closest = index
			closest_distance = distance
		}
	}
	return closest
}

draw_text_field :: proc(field: Text_Field, bounds: rl.Rectangle) {
	draw_rounded(bounds, UI_PANEL_COLOR)
	draw_rounded_border(bounds, ACCENT_COLOR)

	text := field_text(field)
	text_x := bounds.x + TEXT_FIELD_PADDING
	text_y := bounds.y + (bounds.height - UI_FONT_SIZE) / 2

	if has_field_selection(field) {
		start, end := field_selection(field)
		start_x := text_x + f32(measure_label(text[:start]))
		end_x := text_x + f32(measure_label(text[:end]))
		rl.DrawRectangleRec({start_x, text_y - 2, end_x - start_x, UI_FONT_SIZE + 4}, UI_HIGHLIGHT_COLOR)
	}

	draw_label(text, text_x, text_y, UI_TEXT_COLOR)

	if is_caret_visible() {
		caret_x := text_x + f32(measure_label(text[:field.caret])) + 1
		rl.DrawLineEx({caret_x, text_y}, {caret_x, text_y + UI_FONT_SIZE}, TEXT_FIELD_CARET_WIDTH, UI_TEXT_COLOR)
	}
}

destroy_text_field :: proc(field: ^Text_Field) {
	strings.builder_destroy(&field.buffer)
}
