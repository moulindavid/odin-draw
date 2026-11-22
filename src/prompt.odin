package main

import rl "vendor:raylib"

PROMPT_WIDTH :: 480
PROMPT_HEIGHT :: 130
PROMPT_PADDING :: 20
PROMPT_BUTTON_WIDTH :: 100
PROMPT_BUTTON_HEIGHT :: 32
PROMPT_BUTTON_GAP :: 8

Prompt_Kind :: enum {
	Overwrite,
}

Prompt_Choice :: enum {
	None,
	Replace,
	Cancel,
}

@(rodata)
OVERWRITE_CHOICES := [?]Prompt_Choice{.Replace, .Cancel}

Prompt :: struct {
	is_open: bool,
	kind:    Prompt_Kind,
}

open_prompt :: proc(prompt: ^Prompt, kind: Prompt_Kind) {
	prompt.is_open = true
	prompt.kind = kind
}

prompt_message :: proc(kind: Prompt_Kind) -> string {
	switch kind {
	case .Overwrite:
		return "A file with this name already exists. Replace it?"
	}
	return ""
}

prompt_choices :: proc(kind: Prompt_Kind) -> []Prompt_Choice {
	switch kind {
	case .Overwrite:
		return OVERWRITE_CHOICES[:]
	}
	return nil
}

choice_label :: proc(choice: Prompt_Choice) -> string {
	switch choice {
	case .None:
		return ""
	case .Replace:
		return "Replace"
	case .Cancel:
		return "Cancel"
	}
	return ""
}

update_prompt :: proc(prompt: ^Prompt) -> Prompt_Choice {
	choices := prompt_choices(prompt.kind)
	choice := Prompt_Choice.None

	if rl.IsKeyPressed(.ESCAPE) {
		choice = .Cancel
	} else if rl.IsKeyPressed(.ENTER) || rl.IsKeyPressed(.KP_ENTER) {
		choice = choices[0]
	} else {
		for candidate, index in choices {
			if is_clicked(prompt_button_bounds(index)) {
				choice = candidate
			}
		}
	}

	if choice != .None {
		prompt.is_open = false
	}
	return choice
}

prompt_bounds :: proc() -> rl.Rectangle {
	return centered_rectangle(PROMPT_WIDTH, PROMPT_HEIGHT)
}

prompt_button_bounds :: proc(index: int) -> rl.Rectangle {
	panel := prompt_bounds()
	right := panel.x + panel.width - PROMPT_PADDING
	x := right - f32(index + 1) * PROMPT_BUTTON_WIDTH - f32(index) * PROMPT_BUTTON_GAP
	y := panel.y + panel.height - PROMPT_PADDING - PROMPT_BUTTON_HEIGHT
	return {x, y, PROMPT_BUTTON_WIDTH, PROMPT_BUTTON_HEIGHT}
}

draw_prompt :: proc(prompt: Prompt) {
	if !prompt.is_open {
		return
	}

	draw_overlay()
	panel := prompt_bounds()
	draw_panel(panel)
	draw_label(prompt_message(prompt.kind), panel.x + PROMPT_PADDING, panel.y + PROMPT_PADDING, UI_TEXT_COLOR)

	for choice, index in prompt_choices(prompt.kind) {
		draw_button(prompt_button_bounds(index), choice_label(choice), is_primary = index == 0)
	}
}
