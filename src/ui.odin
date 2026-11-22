package main

import "core:strings"
import rl "vendor:raylib"

UI_FONT_SIZE :: 16
UI_CORNER_RADIUS :: 8.0
UI_CORNER_SEGMENTS :: 8
UI_PANEL_COLOR :: rl.Color{255, 255, 255, 255}
UI_BORDER_COLOR :: rl.Color{220, 220, 225, 255}
UI_HOVER_COLOR :: rl.Color{240, 240, 246, 255}
UI_HIGHLIGHT_COLOR :: rl.Color{224, 223, 255, 255}
UI_TEXT_COLOR :: rl.Color{30, 30, 30, 255}
UI_MUTED_TEXT_COLOR :: rl.Color{140, 140, 150, 255}
UI_OVERLAY_COLOR :: rl.Color{0, 0, 0, 40}

is_hovered :: proc(bounds: rl.Rectangle) -> bool {
	return rl.CheckCollisionPointRec(rl.GetMousePosition(), bounds)
}

is_clicked :: proc(bounds: rl.Rectangle) -> bool {
	return rl.IsMouseButtonPressed(.LEFT) && is_hovered(bounds)
}

centered_rectangle :: proc(width, height: f32) -> rl.Rectangle {
	return rl.Rectangle {
		x = (f32(rl.GetScreenWidth()) - width) / 2,
		y = (f32(rl.GetScreenHeight()) - height) / 2,
		width = width,
		height = height,
	}
}

draw_overlay :: proc() {
	rl.DrawRectangle(0, 0, rl.GetScreenWidth(), rl.GetScreenHeight(), UI_OVERLAY_COLOR)
}

draw_rounded :: proc(bounds: rl.Rectangle, color: rl.Color) {
	rl.DrawRectangleRounded(bounds, roundness_for(bounds), UI_CORNER_SEGMENTS, color)
}

draw_rounded_border :: proc(bounds: rl.Rectangle, color: rl.Color) {
	rl.DrawRectangleRoundedLinesEx(bounds, roundness_for(bounds), UI_CORNER_SEGMENTS, 1, color)
}

roundness_for :: proc(bounds: rl.Rectangle) -> f32 {
	return min(1, 2 * UI_CORNER_RADIUS / min(bounds.width, bounds.height))
}

draw_panel :: proc(bounds: rl.Rectangle) {
	draw_rounded(bounds, UI_PANEL_COLOR)
	draw_rounded_border(bounds, UI_BORDER_COLOR)
}

draw_button :: proc(bounds: rl.Rectangle, label: string, is_primary := false) {
	if is_primary {
		draw_rounded(bounds, ACCENT_COLOR)
		draw_text_centered(bounds, label, UI_PANEL_COLOR)
		return
	}
	draw_rounded(bounds, UI_HOVER_COLOR if is_hovered(bounds) else UI_PANEL_COLOR)
	draw_rounded_border(bounds, UI_BORDER_COLOR)
	draw_text_centered(bounds, label, UI_TEXT_COLOR)
}

draw_label :: proc(text: string, x, y: f32, color: rl.Color) {
	rl.DrawText(strings.clone_to_cstring(text, context.temp_allocator), i32(x), i32(y), UI_FONT_SIZE, color)
}

draw_text_centered :: proc(bounds: rl.Rectangle, text: string, color: rl.Color) {
	width := f32(measure_label(text))
	draw_label(text, bounds.x + (bounds.width - width) / 2, bounds.y + (bounds.height - UI_FONT_SIZE) / 2, color)
}

measure_label :: proc(text: string) -> i32 {
	return rl.MeasureText(strings.clone_to_cstring(text, context.temp_allocator), UI_FONT_SIZE)
}

fit_label_from_end :: proc(text: string, max_width: f32) -> string {
	ELLIPSIS :: "..."
	if f32(measure_label(text)) <= max_width {
		return text
	}
	tail := text
	for len(tail) > 0 && f32(measure_label(strings.concatenate({ELLIPSIS, tail}, context.temp_allocator))) > max_width {
		tail = tail[1:]
	}
	return strings.concatenate({ELLIPSIS, tail}, context.temp_allocator)
}
