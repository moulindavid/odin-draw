package main

import rl "vendor:raylib"

MENU_BUTTON_GAP :: 8
MENU_WIDTH :: 240
MENU_ITEM_HEIGHT :: 32
MENU_PADDING :: 6
MENU_OFFSET :: 6
MENU_ITEM_TEXT_INSET :: 10
MENU_ICON_WIDTH :: 16
MENU_ICON_LINE_GAP :: 5
MENU_ICON_STROKE :: 1.5

Menu_Item :: struct {
	action:   File_Action,
	label:    string,
	shortcut: string,
}

@(rodata)
MENU_ITEMS := [?]Menu_Item {
	{.New, "New", "Ctrl+N"},
	{.Open, "Open...", "Ctrl+O"},
	{.Save, "Save", "Ctrl+S"},
	{.Save_As, "Save as...", "Ctrl+Shift+S"},
}

Menu :: struct {
	is_open: bool,
}

update_menu :: proc(menu: ^Menu) -> (action: File_Action, consumed: bool) {
	if is_clicked(menu_button_bounds()) {
		menu.is_open = !menu.is_open
		return .None, true
	}
	if !menu.is_open {
		return .None, false
	}

	if rl.IsKeyPressed(.ESCAPE) {
		menu.is_open = false
		return .None, true
	}
	if !rl.IsMouseButtonPressed(.LEFT) {
		return .None, true
	}

	menu.is_open = false
	for item, index in MENU_ITEMS {
		if is_hovered(menu_item_bounds(index)) {
			return item.action, true
		}
	}
	return .None, true
}

menu_button_bounds :: proc() -> rl.Rectangle {
	toolbar := toolbar_bounds()
	size := toolbar.height
	return {toolbar.x - MENU_BUTTON_GAP - size, toolbar.y, size, size}
}

menu_panel_bounds :: proc() -> rl.Rectangle {
	button := menu_button_bounds()
	height := f32(len(MENU_ITEMS)) * MENU_ITEM_HEIGHT + 2 * MENU_PADDING
	return {button.x, button.y + button.height + MENU_OFFSET, MENU_WIDTH, height}
}

menu_item_bounds :: proc(index: int) -> rl.Rectangle {
	panel := menu_panel_bounds()
	y := panel.y + MENU_PADDING + f32(index) * MENU_ITEM_HEIGHT
	return {panel.x + MENU_PADDING, y, panel.width - 2 * MENU_PADDING, MENU_ITEM_HEIGHT}
}

draw_menu :: proc(menu: Menu) {
	draw_menu_button(menu.is_open)
	if !menu.is_open {
		return
	}

	draw_panel(menu_panel_bounds())
	for item, index in MENU_ITEMS {
		bounds := menu_item_bounds(index)
		if is_hovered(bounds) {
			draw_rounded(bounds, UI_HOVER_COLOR)
		}
		text_y := bounds.y + (MENU_ITEM_HEIGHT - UI_FONT_SIZE) / 2
		draw_label(item.label, bounds.x + MENU_ITEM_TEXT_INSET, text_y, UI_TEXT_COLOR)
		shortcut_x := bounds.x + bounds.width - MENU_ITEM_TEXT_INSET - f32(measure_label(item.shortcut))
		draw_label(item.shortcut, shortcut_x, text_y, UI_MUTED_TEXT_COLOR)
	}
}

draw_menu_button :: proc(is_open: bool) {
	button := menu_button_bounds()
	draw_panel(button)
	if is_open {
		draw_rounded(expand_rectangle(button, -TOOLBAR_PADDING), UI_HIGHLIGHT_COLOR)
	}

	center := rl.Vector2{button.x + button.width / 2, button.y + button.height / 2}
	for offset in -1 ..= 1 {
		y := center.y + f32(offset) * MENU_ICON_LINE_GAP
		left := rl.Vector2{center.x - MENU_ICON_WIDTH / 2, y}
		right := rl.Vector2{center.x + MENU_ICON_WIDTH / 2, y}
		rl.DrawLineEx(left, right, MENU_ICON_STROKE, UI_TEXT_COLOR)
	}
}
