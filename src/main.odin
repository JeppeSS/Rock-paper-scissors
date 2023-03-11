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


	for term.win_terminal_running(p_terminal) {
 		if inp.is_key_down(p_terminal.p_input_manager, .KEY_ESC) {
 			term.win_terminal_stop(p_terminal)
 		}


	}
}