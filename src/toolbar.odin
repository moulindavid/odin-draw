package main

import "core:fmt"
import "core:math"
import rl "vendor:raylib"

TOOLBAR_BUTTON_SIZE :: 40
TOOLBAR_PADDING :: 6
TOOLBAR_MARGIN_TOP :: 12
TOOLBAR_ROUNDNESS :: 0.25
TOOLBAR_CORNER_SEGMENTS :: 8
TOOLBAR_BACKGROUND :: rl.Color{255, 255, 255, 255}
TOOLBAR_BORDER :: rl.Color{220, 220, 225, 255}
TOOLBAR_ACTIVE_BUTTON :: rl.Color{224, 223, 255, 255}
TOOLBAR_ICON_COLOR :: rl.Color{30, 30, 30, 255}
TOOLBAR_ICON_STROKE :: 1.5
TOOLBAR_ICON_INSET :: 12
TOOLBAR_SHORTCUT_FONT_SIZE :: 10
TOOLBAR_SHORTCUT_COLOR :: rl.Color{140, 140, 150, 255}

toolbar_bounds :: proc() -> rl.Rectangle {
	tool_count := f32(len(Tool))
	width := tool_count * TOOLBAR_BUTTON_SIZE + (tool_count + 1) * TOOLBAR_PADDING
	height := f32(TOOLBAR_BUTTON_SIZE + 2 * TOOLBAR_PADDING)
	return rl.Rectangle {
		x = (f32(rl.GetScreenWidth()) - width) / 2,
		y = TOOLBAR_MARGIN_TOP,
		width = width,
		height = height,
	}
}

tool_button_bounds :: proc(tool: Tool) -> rl.Rectangle {
	toolbar := toolbar_bounds()
	return rl.Rectangle {
		x = toolbar.x + TOOLBAR_PADDING + f32(tool) * (TOOLBAR_BUTTON_SIZE + TOOLBAR_PADDING),
		y = toolbar.y + TOOLBAR_PADDING,
		width = TOOLBAR_BUTTON_SIZE,
		height = TOOLBAR_BUTTON_SIZE,
	}
}

is_over_toolbar :: proc(screen_point: rl.Vector2) -> bool {
	return rl.CheckCollisionPointRec(screen_point, toolbar_bounds())
}

tool_from_toolbar_click :: proc(current: Tool) -> Tool {
	if !rl.IsMouseButtonPressed(.LEFT) {
		return current
	}
	cursor := rl.GetMousePosition()
	for tool in Tool {
		if rl.CheckCollisionPointRec(cursor, tool_button_bounds(tool)) {
			return tool
		}
	}
	return current
}

draw_toolbar :: proc(active_tool: Tool) {
	toolbar := toolbar_bounds()
	rl.DrawRectangleRounded(toolbar, TOOLBAR_ROUNDNESS, TOOLBAR_CORNER_SEGMENTS, TOOLBAR_BACKGROUND)
	rl.DrawRectangleRoundedLinesEx(toolbar, TOOLBAR_ROUNDNESS, TOOLBAR_CORNER_SEGMENTS, 1, TOOLBAR_BORDER)

	for tool in Tool {
		button := tool_button_bounds(tool)
		if tool == active_tool {
			rl.DrawRectangleRounded(button, TOOLBAR_ROUNDNESS, TOOLBAR_CORNER_SEGMENTS, TOOLBAR_ACTIVE_BUTTON)
		}
		draw_tool_icon(tool, button)
		draw_tool_shortcut(tool, button)
	}
}

draw_tool_icon :: proc(tool: Tool, button: rl.Rectangle) {
	top_left := rl.Vector2{button.x + TOOLBAR_ICON_INSET, button.y + TOOLBAR_ICON_INSET}
	bottom_right := rl.Vector2{button.x + button.width - TOOLBAR_ICON_INSET, button.y + button.height - TOOLBAR_ICON_INSET}
	bottom_left := rl.Vector2{top_left.x, bottom_right.y}
	top_right := rl.Vector2{bottom_right.x, top_left.y}

	switch tool {
	case .Rectangle:
		rl.DrawRectangleLinesEx(rectangle_from_corners(top_left, bottom_right), TOOLBAR_ICON_STROKE, TOOLBAR_ICON_COLOR)
	case .Ellipse:
		draw_ellipse_outline(top_left, bottom_right, TOOLBAR_ICON_STROKE, TOOLBAR_ICON_COLOR)
	case .Arrow:
		draw_arrow(bottom_left, top_right, TOOLBAR_ICON_STROKE, TOOLBAR_ICON_COLOR)
	case .Line:
		draw_polyline([]rl.Vector2{bottom_left, top_right}, TOOLBAR_ICON_STROKE, TOOLBAR_ICON_COLOR)
	case .Freehand:
		draw_squiggle(top_left, bottom_right)
	}
}

draw_squiggle :: proc(top_left, bottom_right: rl.Vector2) {
	SQUIGGLE_POINTS :: 16
	width := bottom_right.x - top_left.x
	middle_y := (top_left.y + bottom_right.y) / 2
	amplitude := (bottom_right.y - top_left.y) / 3

	points: [SQUIGGLE_POINTS]rl.Vector2
	for &point, index in points {
		progress := f32(index) / (SQUIGGLE_POINTS - 1)
		point = {top_left.x + progress * width, middle_y + amplitude * math.sin(progress * math.TAU)}
	}
	draw_polyline(points[:], TOOLBAR_ICON_STROKE, TOOLBAR_ICON_COLOR)
}

draw_tool_shortcut :: proc(tool: Tool, button: rl.Rectangle) {
	number_key := TOOL_SHORTCUTS[tool][1]
	label := fmt.ctprintf("%c", rune(number_key))
	x := i32(button.x + button.width) - rl.MeasureText(label, TOOLBAR_SHORTCUT_FONT_SIZE) - 3
	y := i32(button.y + button.height) - TOOLBAR_SHORTCUT_FONT_SIZE - 2
	rl.DrawText(label, x, y, TOOLBAR_SHORTCUT_FONT_SIZE, TOOLBAR_SHORTCUT_COLOR)
}
