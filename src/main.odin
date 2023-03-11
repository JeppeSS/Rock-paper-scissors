package main

import "core:fmt"

import term "terminal"
import inp "input"




main :: proc() {
	p_console, err := term.win_console_create()
	if(err != nil){
		fmt.println("[ERROR] Could not construct console: ", err)
		return
	}
	defer term.win_console_destroy(p_console)


	for term.win_console_running(p_console) {
 		if inp.is_key_down(p_console.p_input_manager, .KEY_ESC) {
 			term.win_console_stop(p_console)
 		}


	}
}