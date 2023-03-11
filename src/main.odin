package main

import "core:fmt"

import term "terminal"
import inp "input"

main :: proc() {
	p_terminal, err := term.win_terminal_create()
	if(err != nil){
		fmt.println("[ERROR] Could not construct terminal: ", err)
		return
	}
	defer term.win_terminal_destroy(p_terminal)

	x := 0
	y := 0

	term.terminal_hide_cursor()
	for term.win_terminal_running(p_terminal) {
 		if inp.is_key_down(p_terminal.p_input_manager, .KEY_ESC) {
 			term.win_terminal_stop(p_terminal)
 		}

		if inp.is_key_down(p_terminal.p_input_manager, .KEY_W){
			y = y - 1
			term.terminal_move_cursor(x, y)
		}

		if inp.is_key_down(p_terminal.p_input_manager, .KEY_S){
			y = y + 1
			term.terminal_move_cursor(x, y)
		}

		if inp.is_key_down(p_terminal.p_input_manager, .KEY_A){
			x = x - 1
			term.terminal_move_cursor(x, y)
		}

		if inp.is_key_down(p_terminal.p_input_manager, .KEY_D){
			x = x + 1
			term.terminal_move_cursor(x, y)

		}

		if inp.is_key_down(p_terminal.p_input_manager, .KEY_B){
			fmt.printf("X")
			x = x + 1
			term.terminal_move_cursor(x, y)
		}
	}
}