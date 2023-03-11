package main

import "core:fmt"

import "terminal"
import inp "input"

main :: proc() {
	p_terminal, err := terminal.win_terminal_create()
	if(err != nil){
		fmt.println("[ERROR] Could not construct terminal: ", err)
		return
	}
	defer terminal.win_terminal_destroy(p_terminal)

	// Setup
	terminal.hide_cursor()
	
	
	for terminal.win_terminal_running(p_terminal) {
		print_heading()	
		print_options()
		print_input_field()
	}
}


print_heading :: proc() {
	terminal.write_at(0, 1, "*********************************************")
	terminal.write_at(0, 2, "***          ROCK, PAPER, SCISSORS        ***")
	terminal.write_at(0, 3, "*********************************************")
}

print_options :: proc() {
	terminal.write_at(0, 6,  "Please select your move:")
	terminal.write_at(0, 8,  "1. Rock")
	terminal.write_at(0, 10, "2. Paper")
	terminal.write_at(0, 12, "3. Scissors")
	terminal.write_at(0, 14, "4. Quit")
}

print_input_field :: proc() {
	terminal.write_at(0, 18, ">")
}