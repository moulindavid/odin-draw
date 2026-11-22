package main

import "core:strings"
import rl "vendor:raylib"

TEXT_FONT_SIZE :: 20.0
TEXT_LINE_HEIGHT :: 1.25
DEFAULT_FONT_BASE_SIZE :: 10.0

text_lines :: proc(content: string) -> []string {
	return strings.split(content, "\n", context.temp_allocator)
}

text_line_height :: proc(font_size: f32) -> f32 {
	return font_size * TEXT_LINE_HEIGHT
}

text_spacing :: proc(font_size: f32) -> f32 {
	return font_size / DEFAULT_FONT_BASE_SIZE
}

measure_text_line :: proc(line: string, font_size: f32) -> f32 {
	line_text := strings.clone_to_cstring(line, context.temp_allocator)
	return rl.MeasureTextEx(rl.GetFontDefault(), line_text, font_size, text_spacing(font_size)).x
}

measure_text_block :: proc(content: string, font_size: f32) -> rl.Vector2 {
	lines := text_lines(content)
	width: f32
	for line in lines {
		width = max(width, measure_text_line(line, font_size))
	}
	return {width, f32(len(lines)) * text_line_height(font_size)}
}

text_bounds :: proc(text: Text) -> rl.Rectangle {
	size := measure_text_block(text.content, text.font_size)
	return {text.position.x, text.position.y, size.x, size.y}
}

draw_text_block :: proc(content: string, position: rl.Vector2, font_size: f32, color: rl.Color) {
	line_height := text_line_height(font_size)
	for line, index in text_lines(content) {
		line_text := strings.clone_to_cstring(line, context.temp_allocator)
		line_position := position + {0, f32(index) * line_height}
		rl.DrawTextEx(rl.GetFontDefault(), line_text, line_position, font_size, text_spacing(font_size), color)
	}
}
