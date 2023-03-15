package main

import "core:fmt"
import "core:math/rand"
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

RoundState_e :: enum {
	Win,
	Lose,
	Draw,
}

Hand_e :: enum {
	Rock     = 1,
	Paper    = 2,
	Scissors = 3,
}

EventType_e :: enum {
	QUIT_EVENT,
	SHOW_HAND_EVENT,
	WIN_ROUND_EVENT,
	LOSE_ROUND_EVENT,
	DRAW_ROUND_EVENT,
	CHANGE_SCENE,
}



EventData_u :: union {
	Hand_e,
	string,
}

GameEvent :: struct {
	event_type: EventType_e,
	data: EventData_u,
}

main :: proc() {
	p_terminal, err := terminal.win_terminal_create()
	if(err != nil){
		fmt.println("[ERROR] Could not construct terminal: ", err)
		return
	}
	defer terminal.win_terminal_destroy(p_terminal)

	options_input_field := InputField_t{value = 0, is_valid = false, submit = false}

	hands := [?]Hand_e{.Rock, .Paper, .Scissors}
	ai_hand := rand.choice(hands[:])

	outcomes := [3][3]RoundState_e{
		{.Draw, .Lose, .Win},
		{.Win, .Draw, .Lose},
		{.Lose, .Win, .Draw},
	}

	event_queue: [dynamic]GameEvent
	defer delete(event_queue)

	scene := "Main"

	terminal.hide_cursor()
	for terminal.win_terminal_running(p_terminal) {

		if scene == "Main" {
			print_heading()	
			print_options()
			print_input_field(&options_input_field)

			listen_for_input(p_terminal, &options_input_field)
			event, ok := handle_input_field(&options_input_field).?
			if ok do append(&event_queue, event)
		
		}
		else if scene == "Win" {
			terminal.write_at(5, 5, "You win!")
		}
		else if scene == "Lose" {
			terminal.write_at(5, 5, "You lose!")
		}
		else if scene == "Draw" {
			terminal.write_at(5, 5, "Its a draw!")
		}




		// TODO[Jeppe]: Move this to procedure
		for len(event_queue) > 0 {
			event := pop(&event_queue)
			if event.event_type == .QUIT_EVENT {
				terminal.stop(p_terminal)
			}
			else if event.event_type == .SHOW_HAND_EVENT {
				outcome := outcomes[u8(event.data.(Hand_e)) - 1][u8(ai_hand) - 1]
				switch outcome {
					case .Win:
						append(&event_queue, GameEvent{ event_type = .WIN_ROUND_EVENT})
					case .Lose:
						append(&event_queue, GameEvent{ event_type = .LOSE_ROUND_EVENT})
					case .Draw:
						append(&event_queue, GameEvent{ event_type = .DRAW_ROUND_EVENT})
				}
			}
			else if event.event_type == .WIN_ROUND_EVENT {
				append(&event_queue, GameEvent{ event_type = .CHANGE_SCENE, data = "Win"})
			}
			else if event.event_type == .LOSE_ROUND_EVENT {
				append(&event_queue, GameEvent{ event_type = .CHANGE_SCENE, data = "Lose"})
			}
			else if event.event_type == .DRAW_ROUND_EVENT {
				append(&event_queue, GameEvent{ event_type = .CHANGE_SCENE, data = "Draw"})
			}
			else if event.event_type == .CHANGE_SCENE {
				terminal.clear()
				scene = event.data.(string)
			}
		}

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


listen_for_input :: proc(p_terminal: ^terminal.WinTerminal_t, p_input_field: ^InputField_t) {
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

handle_input_field :: proc(p_input_field: ^InputField_t) -> Maybe(GameEvent) {
	if p_input_field.submit {
		game_event := handle_user_input(p_input_field)
		p_input_field.submit = false
		p_input_field.is_valid = false
		p_input_field.value = 0
		return game_event
	}

	return nil
}


handle_user_input :: proc(p_input_field: ^InputField_t) -> GameEvent {
	if p_input_field.value == QUIT {
		return GameEvent{ event_type = .QUIT_EVENT }
	}
	

	return GameEvent{ event_type = .SHOW_HAND_EVENT, data = cast(Hand_e)p_input_field.value }
}