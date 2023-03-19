package main

import "core:fmt"
import "core:math/rand"
import "core:log"

import "terminal"
import "event"


Game_Context_t :: struct {
	p_event_dispatcher: ^event.Event_Dispatcher_t,
	p_terminal: ^terminal.WinTerminal_t,
	p_game_state: ^Game_State_t,
}

InputField_t :: struct {
	value:    u8,
	is_valid: bool,
}

Game_State_t :: struct {
	scene: string,
	ai_hand: u8,
	input_field: InputField_t,
}

ROCK ::1
PAPER :: 2
SCISSORS :: 3
QUIT :: 4

RoundState_e :: enum {
	Win,
	Lose,
	Draw,
}

main :: proc() {

	p_terminal, err := terminal.win_terminal_create()
	if(err != nil){
		fmt.println("[ERROR] Could not construct terminal: ", err)
		return
	}
	defer terminal.win_terminal_destroy(p_terminal)

	p_event_dispatcher := event.create_event_dispatcher()
	defer event.destroy_event_dispatcher(p_event_dispatcher)

	game_context := Game_Context_t{ 
		p_event_dispatcher = p_event_dispatcher,
		p_terminal         = p_terminal,
		p_game_state       = create_game_state(),
	}
	defer destroy_game_state(game_context.p_game_state)

	register_event_handlers(p_event_dispatcher)

	terminal.hide_cursor()
	for terminal.win_terminal_running(p_terminal) {
		p_game_state := game_context.p_game_state

		if p_game_state.scene == "Main" {
			print_heading()	
			print_options()
			print_input_field(p_game_state.input_field)
			listen_for_input(&game_context, &p_game_state.input_field)
		}
		else if p_game_state.scene == "Win" {
			terminal.write_at(5, 5, "You win!")
		}
		else if p_game_state.scene == "Lose" {
			terminal.write_at(5, 5, "You lose!")
		}
		else if p_game_state.scene == "Draw" {
			terminal.write_at(5, 5, "Its a draw!")
		}

	}
}

create_game_state :: proc() -> ^Game_State_t {
	p_game_state := new(Game_State_t)
	init_game_state(p_game_state)
	return p_game_state
}

init_game_state :: proc(p_game_state: ^Game_State_t) {
	hands := [3]u8{ROCK, PAPER, SCISSORS}

	p_game_state.scene       = "Main"
	p_game_state.ai_hand     = rand.choice(hands[:])
	p_game_state.input_field = InputField_t{value = 0, is_valid = false}
}

destroy_game_state :: proc(p_game_state: ^Game_State_t) {
	free(p_game_state)
}

register_event_handlers :: proc(p_event_dispatcher: ^event.Event_Dispatcher_t) {
	event.register_handler(p_event_dispatcher, "QUIT_EVENT", quit_event_handler)
	event.register_handler(p_event_dispatcher, "SHOW_HAND_EVENT", show_hand_event_handler)
	event.register_handler(p_event_dispatcher, "CHANGE_SCENE_EVENT", change_scene_event_handler)
	event.register_handler(p_event_dispatcher, "INPUT_SUBMIT_EVENT", input_submit_event_handler)
}

input_submit_event_handler :: proc(p_game_context: rawptr, p_event_data: rawptr){
	p_game_context := cast(^Game_Context_t)p_game_context
	p_input_field := cast(^InputField_t)p_event_data

	if p_input_field.value == QUIT {
		event.dispatch_event(p_game_context.p_event_dispatcher, "QUIT_EVENT", nil, p_game_context)
	} else if p_input_field.value == ROCK || p_input_field.value == PAPER || p_input_field.value == SCISSORS {
		event.dispatch_event(p_game_context.p_event_dispatcher, "SHOW_HAND_EVENT", &p_input_field.value, p_game_context)
	}

	p_input_field.is_valid = false
	p_input_field.value = 0

}

quit_event_handler :: proc(p_game_context: rawptr, p_event_data: rawptr){
	p_game_context := cast(^Game_Context_t)p_game_context
	terminal.stop(p_game_context.p_terminal)
}

show_hand_event_handler :: proc(p_game_context: rawptr, p_event_data: rawptr){
	outcomes := [3][3]RoundState_e{
		{.Draw, .Lose, .Win},
		{.Win, .Draw, .Lose},
		{.Lose, .Win, .Draw},
	}

	p_game_context := cast(^Game_Context_t)p_game_context
	p_game_state   := p_game_context.p_game_state
	// TODO[Jeppe]: Can this process be simplified?
	p_hand := cast(^u8)p_event_data

	outcome := outcomes[p_hand^ - 1][u8(p_game_state.ai_hand) - 1]
	new_scene := ""
	switch outcome {
		case .Win:
			new_scene = "Win"
		case .Lose:		
			new_scene = "Lose"
		case .Draw:
			new_scene = "Draw"
	}

	event.dispatch_event(p_game_context.p_event_dispatcher, "CHANGE_SCENE_EVENT", &new_scene, p_game_context)
}

change_scene_event_handler :: proc(p_game_context: rawptr, p_event_data: rawptr) {
	p_game_context := cast(^Game_Context_t)p_game_context
	p_game_state   := p_game_context.p_game_state
	p_scene := cast(^string)p_event_data
	terminal.clear()
	p_game_state.scene = p_scene^
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

print_input_field :: proc(input_field: InputField_t) {
	terminal.write_at(0, 18, ">")
	if input_field.is_valid {
		value := fmt.aprintf("%d", input_field.value)
		terminal.write_at(3, 18, value)
	} else {
		terminal.delete_at(3, 18)
	}
}


listen_for_input :: proc(p_game_context: ^Game_Context_t, p_input_field: ^InputField_t) {
	p_terminal := p_game_context.p_terminal
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
			event.dispatch_event(p_game_context.p_event_dispatcher, "INPUT_SUBMIT_EVENT", p_input_field, p_game_context)
		}
	}
}