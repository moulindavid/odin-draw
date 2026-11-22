package main

import "core:strings"
import rl "vendor:raylib"

type_into :: proc(buffer: ^strings.Builder) {
	for character := rl.GetCharPressed(); character != 0; character = rl.GetCharPressed() {
		strings.write_rune(buffer, character)
	}
	if is_key_typed(.BACKSPACE) && strings.builder_len(buffer^) > 0 {
		strings.pop_rune(buffer)
	}
}

is_enter_typed :: proc() -> bool {
	return is_key_typed(.ENTER) || is_key_typed(.KP_ENTER)
}

is_key_typed :: proc(key: rl.KeyboardKey) -> bool {
	return rl.IsKeyPressed(key) || rl.IsKeyPressedRepeat(key)
}
