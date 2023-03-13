package main

import "core:fmt"
import "terminal"


InputField_t :: struct {
	value:    u8,
	is_valid: bool,
	submit:   bool,
}

ROCK ::1
PAPER :: 2
SCISSORS :: 3
QUIT :: 4

main :: proc() {
	p_terminal, err := terminal.win_terminal_create()
	if(err != nil){
		fmt.println("[ERROR] Could not construct terminal: ", err)
		return
	}
	defer terminal.win_terminal_destroy(p_terminal)

	options_input_field := InputField_t{is_valid = false, submit = false}

	terminal.hide_cursor()
	for terminal.win_terminal_running(p_terminal) {
		print_heading()	
		print_options()

		fetch_user_input(p_terminal, &options_input_field)
		print_input_field(&options_input_field)


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

print_input_field :: proc(p_input_field: ^InputField_t) {
	terminal.write_at(0, 18, ">")
	if p_input_field.is_valid {
		value := fmt.aprintf("%d", p_input_field.value)
		terminal.write_at(3, 18, value)
	} else {
		terminal.delete_at(3, 18)
	}
}


fetch_user_input :: proc(p_terminal: ^terminal.WinTerminal_t, p_input_field: ^InputField_t) {
	if terminal.is_key_down(p_terminal, .KEY_1) {
		p_input_field.value = ROCK
		p_input_field.is_valid = true
	}

	if terminal.is_key_down(p_terminal, .KEY_2) {
		p_input_field.value = PAPER
		p_input_field.is_valid = true
	}

	if terminal.is_key_down(p_terminal, .KEY_3) {
		p_input_field.value = SCISSORS
		p_input_field.is_valid = true
	}

	if terminal.is_key_down(p_terminal, .KEY_4) {
		p_input_field.value = QUIT
		p_input_field.is_valid = true
	}

	if terminal.is_key_down(p_terminal, .KEY_BACKSPACE) {
		p_input_field.is_valid = false
	}

	if terminal.is_key_down(p_terminal, .KEY_ENTER) {
		if p_input_field.is_valid {
			p_input_field.submit = true
		}
	}
}