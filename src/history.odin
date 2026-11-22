package main

import rl "vendor:raylib"

HISTORY_LIMIT :: 100

History :: struct {
	states:            [dynamic][]Element,
	current:           int,
	recorded_revision: int,
}

init_history :: proc(history: ^History, board: Board) {
	append(&history.states, clone_elements(board.elements[:]))
	history.current = 0
	history.recorded_revision = board.revision
}

record_change :: proc(history: ^History, board: Board) {
	if board.revision == history.recorded_revision {
		return
	}
	history.recorded_revision = board.revision

	if elements_equal(board.elements[:], history.states[history.current]) {
		return
	}

	discard_redo_states(history)
	append(&history.states, clone_elements(board.elements[:]))
	if len(history.states) > HISTORY_LIMIT {
		destroy_elements(history.states[0])
		ordered_remove(&history.states, 0)
	}
	history.current = len(history.states) - 1
}

discard_redo_states :: proc(history: ^History) {
	for len(history.states) > history.current + 1 {
		destroy_elements(pop(&history.states))
	}
}

destroy_history :: proc(history: ^History) {
	for state in history.states {
		destroy_elements(state)
	}
	delete(history.states)
}

update_history_keys :: proc(history: ^History, board: ^Board) -> bool {
	pressed_history_key := rl.IsKeyPressed(.Z) || rl.IsKeyPressed(.Y)
	if !is_control_down() || !pressed_history_key {
		return false
	}
	wants_redo := rl.IsKeyPressed(.Y) || is_shift_down()
	return redo(history, board) if wants_redo else undo(history, board)
}

is_control_down :: proc() -> bool {
	return rl.IsKeyDown(.LEFT_CONTROL) || rl.IsKeyDown(.RIGHT_CONTROL)
}

is_shift_down :: proc() -> bool {
	return rl.IsKeyDown(.LEFT_SHIFT) || rl.IsKeyDown(.RIGHT_SHIFT)
}

undo :: proc(history: ^History, board: ^Board) -> bool {
	if history.current == 0 {
		return false
	}
	history.current -= 1
	restore_current_state(history, board)
	return true
}

redo :: proc(history: ^History, board: ^Board) -> bool {
	if history.current == len(history.states) - 1 {
		return false
	}
	history.current += 1
	restore_current_state(history, board)
	return true
}

restore_current_state :: proc(history: ^History, board: ^Board) {
	replace_elements(board, history.states[history.current])
	history.recorded_revision = board.revision
}
