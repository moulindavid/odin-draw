package main

import "core:fmt"
import "core:strings"
import rl "vendor:raylib"

STATUS_VISIBLE_SECONDS :: 2.5
STATUS_FADE_SECONDS :: 0.5
STATUS_FONT_SIZE :: 16
STATUS_MARGIN :: 16
STATUS_COLOR :: rl.Color{90, 90, 100, 255}

Status :: struct {
	message:  strings.Builder,
	shown_at: f64,
}

show_status :: proc(status: ^Status, format: string, args: ..any) {
	strings.builder_reset(&status.message)
	fmt.sbprintf(&status.message, format, ..args)
	status.shown_at = rl.GetTime()
}

draw_status :: proc(status: Status) {
	remaining := STATUS_VISIBLE_SECONDS - (rl.GetTime() - status.shown_at)
	if remaining <= 0 || strings.builder_len(status.message) == 0 {
		return
	}

	opacity := f32(min(remaining / STATUS_FADE_SECONDS, 1))
	message := strings.clone_to_cstring(strings.to_string(status.message), context.temp_allocator)
	y := rl.GetScreenHeight() - STATUS_MARGIN - STATUS_FONT_SIZE
	rl.DrawText(message, STATUS_MARGIN, y, STATUS_FONT_SIZE, rl.Fade(STATUS_COLOR, opacity))
}

destroy_status :: proc(status: ^Status) {
	strings.builder_destroy(&status.message)
}
