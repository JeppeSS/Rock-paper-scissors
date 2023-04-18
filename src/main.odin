package main

import "core:fmt"
import "core:math/rand"
import "core:time"

import win "core:sys/windows"

//=====================================================================================================================================================================
// TODO[Jeppe]: This is just for now, remove this when these are included in the Odin compiler.
foreign import kernel32 "system:Kernel32.lib"

@(default_calling_convention="stdcall")
foreign kernel32 {
	GetNumberOfConsoleInputEvents :: proc(hConsoleInput: win.HANDLE, lpcNumberOfEvents: win.LPDWORD) -> win.BOOL ---
	ReadConsoleInputW :: proc(hConsoleInput: win.HANDLE, lpBuffer: PINPUT_RECORD, nLength: win.DWORD, lpNumberOfEventsRead: win.LPDWORD) -> win.BOOL ---
}



KEY_EVENT_RECORD :: struct {
	bKeyDown: win.BOOL,
	wRepeatCount: win.WORD,
	wVirtualKeyCode: win.WORD,
	wVirtualScanCode: win.WORD,
	uChar: struct #raw_union {
		UnicodeChar: win.WCHAR,
		AsciiChar: win.CHAR,
	},
	dwControlKeyState: win.WORD,
}

MOUSE_EVENT_RECORD :: struct {
	dwMousePosition: win.COORD,
	dwButtonState: win.DWORD,
	dwControlKeyState: win.DWORD,
	dwEventFlags: win.DWORD,
}


WINDOW_BUFFER_SIZE_RECORD :: struct {
	dwSize: win.COORD,
}

MENU_EVENT_RECORD :: struct {
	dwCommandId: win.UINT,
}

PMENU_EVENT_RECORD :: ^MENU_EVENT_RECORD

FOCUS_EVENT_RECORD :: struct {
	bSetFocus: win.BOOL,
}

INPUT_RECORD :: struct {
	EventType: win.WORD,
	Event: struct #raw_union {
		KeyEvent: KEY_EVENT_RECORD,
		MouseEvent: MOUSE_EVENT_RECORD,
		WindowBufferSizeEvent: WINDOW_BUFFER_SIZE_RECORD,
		MenuEvent: MENU_EVENT_RECORD,
		FocusEvent: FOCUS_EVENT_RECORD,
	},
}

PINPUT_RECORD :: ^INPUT_RECORD

KEY_EVENT :: 0x0001
//=====================================================================================================================================================================


Game_Mode_e :: enum u8 {
    Classic,
    Best_Of,
    Speed,
    Multiplayer,
    None,
}

Round_State_e :: enum u8 {
    Player_1_Win,
    Player_2_Win,
    Draw,
}

Hand_e :: enum u8 {
    Rock    = 0,
    Paper   = 1,
    Scissor = 2,
    None    = 4,    
}

Input_field_t :: struct {
    value: u8,
    is_submitted: bool,
}

Best_Of_Mode_State_t :: struct {
    player_wins: u8,
    ai_wins: u8,
    round_state: Round_State_e,
}

Speed_Mode_State_t :: struct {
    score: int,
    stopwatch: time.Stopwatch,
    is_over: bool,
    round_state: Round_State_e,
}

Game_State_t :: struct {
    game_mode:  Game_Mode_e,
    game_mode_state: union {
        Round_State_e,
        Best_Of_Mode_State_t,
        Speed_Mode_State_t,
    }

    player_1_hand: Hand_e,
    player_2_hand: Hand_e,
    input_field:   Input_field_t,
    is_drawn:      bool,

}


play_round :: proc(player_1_hand: Hand_e, player_2_hand: Hand_e) -> Round_State_e {
    outcome := [3][3]Round_State_e{
	    {.Draw, .Player_2_Win, .Player_1_Win},
		{.Player_1_Win, .Draw, .Player_2_Win},
		{.Player_2_Win, .Player_1_Win, .Draw},
	}
    return outcome[player_1_hand][player_2_hand]
}

get_random_hand :: proc() -> Hand_e {
    POSSIBLE_HANDS :: 3
    random_hand_idx := cast(u8)rand.uint32() % POSSIBLE_HANDS
    return Hand_e(random_hand_idx)
}


// TODO[Jeppe]: Need to fetch player hand.
play_speed :: proc() {
    SECONDS_TO_PLAY :: 30.0
    score    := 0
    running := true

    stopwatch := time.Stopwatch{}
    time.stopwatch_start(&stopwatch)
    for running {
        duration := time.stopwatch_duration(stopwatch)
        seconds  := time.duration_seconds(duration)
        fmt.printf("Time %f\n", seconds)
        fmt.printf("Score %d\n", score)
        if( seconds >= SECONDS_TO_PLAY) {
            running = false
            time.stopwatch_stop(&stopwatch)
        } else {
            ai_hand     := get_random_hand()
            round_state := play_round(.Rock, ai_hand)
            switch round_state {
                case .Player_1_Win: score += 1
                case .Player_2_Win: score -= 1
                case .Draw:         
            }
        }
    }

}

// TODO[Jeppe]: Need to fetch player hands.
play_multiplayer :: proc() {
    ai_hand     := get_random_hand()
    round_state := play_round(.Rock, ai_hand)
    switch round_state {
        case .Player_1_Win: fmt.println("Player 1 wins!")
        case .Player_2_Win: fmt.println("Player 2 wins!")
        case .Draw:         fmt.println("It's a draw!")
    }
}






main :: proc() {
    output_handle := win.GetStdHandle( win.STD_OUTPUT_HANDLE )
	if( output_handle == win.INVALID_HANDLE_VALUE ) {
        // TODO[Jeppe]: Logging
		return
	}

    input_handle := win.GetStdHandle( win.STD_INPUT_HANDLE )
	if( input_handle == win.INVALID_HANDLE_VALUE ) {
        // TODO[Jeppe]: Logging
		return
	}

    // Enable virtual terminal sequences
    {
        buffer_mode: u32 = 0
        if( !win.GetConsoleMode( output_handle, &buffer_mode ) ) {
            // TODO[Jeppe]: Logging
            return
        }

        buffer_mode = buffer_mode | win.ENABLE_VIRTUAL_TERMINAL_PROCESSING
        if( !win.SetConsoleMode( output_handle, buffer_mode ) ) {
            // TODO[Jeppe]: Logging
            return
        }
    }

    // Enable input events
    {
        buffer_mode := win.ENABLE_WINDOW_INPUT | win.ENABLE_MOUSE_INPUT
        if !win.SetConsoleMode( input_handle, buffer_mode ) {
            // TODO[Jeppe]: Logging
		    return
        }
    }

    // Hide cursor
    fmt.printf("\x1b[?25l")
    // Alternate buffer begin
    fmt.printf("\x1b[?1049h") 
    // Clear
    fmt.printf("\x1b[2J")

    game_state := Game_State_t{
        game_mode       = .None,
        game_mode_state = nil,
        input_field     = Input_field_t{ value = 0, is_submitted = false }
        player_1_hand   = .None,
        player_2_hand   = .None,
        is_drawn        = false,

    }

    // Game loop
    is_app_running := true
    for is_app_running {

        // Input processing
        {
            num_events: win.DWORD = 0
            if( !GetNumberOfConsoleInputEvents(input_handle, &num_events)){
                // TODO[Jeppe]: Logging
                return 
            }
            events_read: u32 = 0
            input_records: [64]INPUT_RECORD
            if(!ReadConsoleInputW(input_handle, &input_records[0], num_events, &events_read)){
                // TODO[Jeppe]: Logging
                return
            }

            for input_record in input_records {
                switch(input_record.EventType){
                    case KEY_EVENT:
                        key_event := input_record.Event.KeyEvent
                        if key_event.bKeyDown {
                            p_input_field := &game_state.input_field
                            switch key_event.wVirtualKeyCode {
                                case 0x08: // BACKSPACE
                                    p_input_field.value        = 0
                                    p_input_field.is_submitted = false
                                case 0x0D: // ENTER
                                        p_input_field.is_submitted = true
                                case 0x31: // 1
                                    p_input_field.value        = 1
                                    p_input_field.is_submitted = false
                                case 0x32: // 2
                                    p_input_field.value        = 2
                                    p_input_field.is_submitted = false
                                case 0x33: // 3
                                    p_input_field.value        = 3
                                    p_input_field.is_submitted = false
                                case 0x34: // 4
                                    p_input_field.value        = 4
                                    p_input_field.is_submitted = false
                                case 0x35: // 5
                                    p_input_field.value        = 5
                                    p_input_field.is_submitted = false
                            }
                        }
                }
            }
        }

        #partial switch game_state.game_mode {

            case .None: // Main menu
                render_main_menu(&game_state)
                p_input_field := &game_state.input_field
                if p_input_field.is_submitted && p_input_field.value > 0 && p_input_field.value < 6 {
                    p_input_field.is_submitted = false
                    fmt.printf("\x1b[2J") // Clear
                    game_state.is_drawn = false
                    switch p_input_field.value {
                        case 1: game_state.game_mode = .Classic
                        case 2:
                            game_state.game_mode = .Best_Of
                            game_state.game_mode_state = Best_Of_Mode_State_t{ player_wins = 0, ai_wins = 0}
                        case 3:
                            game_state.game_mode = .Speed
                            game_state.game_mode_state = Speed_Mode_State_t{ score = 0, stopwatch = time.Stopwatch{}, is_over = false }
                            p_speed_mode := &game_state.game_mode_state.(Speed_Mode_State_t)
                            time.stopwatch_start(&p_speed_mode.stopwatch)
                        case 5: is_app_running = false
                    }
                    p_input_field.value        = 0
                    p_input_field.is_submitted = false
                }


            case .Classic: // Classic game mode
                if game_state.player_1_hand == .None {
                    render_classic_selection(&game_state)
                    p_input_field := &game_state.input_field
                    if p_input_field.is_submitted && p_input_field.value < 5 {
                        fmt.printf("\x1b[2J") // Clear
                        switch p_input_field.value {
                            case 1: game_state.player_1_hand = .Rock
                            case 2: game_state.player_1_hand = .Paper
                            case 3: game_state.player_1_hand = .Scissor
                            case 4: is_app_running = false
                        }
                        p_input_field.value = 0
                        p_input_field.is_submitted = false
                        game_state.is_drawn = false
                    }
                } else {
                    if game_state.player_2_hand == .None {
                        game_state.player_2_hand = get_random_hand()
                        game_state.game_mode_state = play_round(game_state.player_1_hand, game_state.player_2_hand)
                    }
                    render_classic_game(&game_state)
                    p_input_field := &game_state.input_field
                    if p_input_field.is_submitted {
                        fmt.printf("\x1b[2J") // Clear
                        game_state.game_mode = .None
                        p_input_field.value = 0
                        p_input_field.is_submitted = false
                        game_state.is_drawn = false
                        game_state.player_1_hand = .None
                        game_state.player_2_hand = .None
                    }
                }

            case .Best_Of:
                if game_state.player_1_hand == .None {
                    render_best_of_selection(&game_state)
                    p_input_field := &game_state.input_field
                    if p_input_field.is_submitted && p_input_field.value < 5 {
                        fmt.printf("\x1b[2J") // Clear
                        switch p_input_field.value {
                            case 1: game_state.player_1_hand = .Rock
                            case 2: game_state.player_1_hand = .Paper
                            case 3: game_state.player_1_hand = .Scissor
                            case 4: is_app_running = false
                        }
                        p_input_field.value = 0
                        p_input_field.is_submitted = false
                        game_state.is_drawn = false
                    }
                } else {
                    p_best_of_state := &game_state.game_mode_state.(Best_Of_Mode_State_t)
                    if game_state.player_2_hand == .None {
                        p_input_field := &game_state.input_field
                        game_state.player_2_hand = get_random_hand()
                        p_best_of_state.round_state = play_round(game_state.player_1_hand, game_state.player_2_hand)
                        switch p_best_of_state.round_state {
                            case .Player_1_Win: p_best_of_state.player_wins += 1
                            case .Player_2_Win: p_best_of_state.ai_wins += 1
                            case .Draw:     
                        }
                        p_input_field.value = 0
                        p_input_field.is_submitted = false
                        game_state.is_drawn = false
                    } 
                    
                    if game_state.player_2_hand != .None {
                        render_best_of_game(&game_state)
                        p_input_field := &game_state.input_field
                        if p_input_field.is_submitted {
                            p_input_field.value = 0
                            p_input_field.is_submitted = false
                            game_state.is_drawn = false
                            game_state.player_1_hand = .None
                            game_state.player_2_hand = .None
                            if( p_best_of_state.player_wins >= 3 || p_best_of_state.ai_wins >= 3) {
                                game_state.game_mode = .None
                                fmt.printf("\x1b[2J") // Clear
                            }

           
                        }
                    }
                }

            case .Speed:
                p_speed_state := &game_state.game_mode_state.(Speed_Mode_State_t)
                duration := time.stopwatch_duration(p_speed_state.stopwatch)
                seconds  := time.duration_seconds(duration)
                if seconds <= 30.0 { // TODO[Jeppe]: Remember to change this
                    if game_state.player_1_hand == .None {
                        render_speed_selection(&game_state)
                        p_input_field := &game_state.input_field
                        if p_input_field.is_submitted && p_input_field.value < 5 {
                            fmt.printf("\x1b[2J") // Clear
                            switch p_input_field.value {
                                case 1: game_state.player_1_hand = .Rock
                                case 2: game_state.player_1_hand = .Paper
                                case 3: game_state.player_1_hand = .Scissor
                                case 4: is_app_running = false
                            }
                                p_input_field.value = 0
                                p_input_field.is_submitted = false
                                game_state.is_drawn = false
                        }
                    } else {
                        if game_state.player_2_hand == .None {
                            p_input_field := &game_state.input_field
                            game_state.player_2_hand = get_random_hand()
                            p_speed_state.round_state = play_round(game_state.player_1_hand, game_state.player_2_hand)
                            switch p_speed_state.round_state {
                                case .Player_1_Win: p_speed_state.score += 1
                                case .Player_2_Win: p_speed_state.score -= 1
                                case .Draw:     
                            }
                            p_input_field.value = 0
                            p_input_field.is_submitted = false
                            game_state.is_drawn = false
                        } 
                    
                        if game_state.player_2_hand != .None {
                            render_speed_game(&game_state)
                            p_input_field := &game_state.input_field
                            if p_input_field.is_submitted {
                                p_input_field.value = 0
                                p_input_field.is_submitted = false
                                game_state.is_drawn = false
                                game_state.player_1_hand = .None
                                game_state.player_2_hand = .None
                            }
                        }
                    }
                } else {
                    if !p_speed_state.is_over{
                        time.stopwatch_stop(&p_speed_state.stopwatch)
                        p_speed_state.is_over = true
                        game_state.is_drawn = false

                    }
                    render_speed_end(&game_state)
                    p_input_field := &game_state.input_field
                    if p_input_field.is_submitted {
                        p_input_field.value = 0
                        p_input_field.is_submitted = false
                        game_state.is_drawn = false
                        game_state.player_1_hand = .None
                        game_state.player_2_hand = .None
                        game_state.game_mode = .None
                    }
                }

        }
    }
    // Alternate buffer end
    fmt.printf("\x1b[?1049l") 
}


render_main_menu :: proc(p_game_state: ^Game_State_t) {
    if !p_game_state.is_drawn {
        write_at(0, 1,  " ____________________________________________________________________________")
        write_at(0, 2,  "|                                                                            |")
        write_at(0, 3,  "|                            ROCK, PAPER, SCISSORS                           |")
        write_at(0, 4,  "|____________________________________________________________________________|")
        write_at(0, 5,  "|                                                                            |")
        write_at(0, 6,  "|                                GAME MODES                                  |")
        write_at(0, 7,  "|____________________________________________________________________________|")
        write_at(0, 8,  "|                                                                            |")
        write_at(0, 9,  "| 1. Classic Game                                                            |")
        write_at(0, 10, "|    - Play the classic Rock, Paper, Scissors game against the computer.     |")
        write_at(0, 11, "|                                                                            |")
        write_at(0, 12, "| 2. Best of Five                                                            |")
        write_at(0, 13, "|    - Play a series of 5 games against the computer.                        |")
        write_at(0, 14, "|    - The first player to win 3 games is the winner.                        |")
        write_at(0, 15, "|                                                                            |")
        write_at(0, 16, "| 3. Time Attack                                                             |")
        write_at(0, 17, "|    - Play against the clock and try to get the highest score possible.     |")
        write_at(0, 18, "|    - Each correct guess earns you points.                                  |")
        write_at(0, 19, "|    - Incorrect guesses deduct points from your score.                      |")
        write_at(0, 20, "|                                                                            |")
        write_at(0, 21, "| 4. Multiplayer                                                             |")
        write_at(0, 22, "|    - Play against a friend on the same computer.                           |")
        write_at(0, 23, "|                                                                            |")
        write_at(0, 24, "| 5. Quit                                                                    |")  
        write_at(0, 25, "|____________________________________________________________________________|")
        write_at(0, 26, "|                                                                            |")
        write_at(0, 27, "| Please enter the number of the game mode you would like to play:           |")
        write_at(0, 28, "|                                                                            |")
        write_at(0, 29, "| >                                                                          |")
        write_at(0, 30, "|____________________________________________________________________________|")
        p_game_state.is_drawn = true
    }

    input_field := p_game_state.input_field
    if input_field.value > 0 {
        value := fmt.aprintf("%d", input_field.value)
		write_at(5, 29, value)
    } else {
        write_at(5, 29, " ")
    }
}


render_best_of_game :: proc(p_game_state: ^Game_State_t) {
    if !p_game_state.is_drawn {
        draw_box_at(0, 1, 76, 30, "_", "_", "|", "|")
        write_at(0, 1, " ")
        write_at(76, 0, " ")
        write_at(30, 3,  "ROCK, PAPER, SCISSORS")
        draw_horizontal_line_at(2, 4, 73, "_")
        write_at(32, 6,  "BEST OUT OF FIVE")
        draw_horizontal_line_at(2, 7, 73, "_")

        best_of_state := p_game_state.game_mode_state.(Best_Of_Mode_State_t)
        player_score := fmt.aprintf("Player Score: %d", best_of_state.player_wins)
        computer_score := fmt.aprintf("Computer Score: %d", best_of_state.ai_wins)

        write_at(15, 9, player_score)
        write_at(45, 9, computer_score)
        draw_horizontal_line_at(2, 10, 73, "_")


        // Draw player hand
        write_at(20, 13, "YOU")
        #partial switch p_game_state.player_1_hand {
            case .Rock:    draw_rock_at(15, 14, true)
            case .Paper:   draw_paper_at(15, 14, true)
            case .Scissor: draw_scissor_at(15, 14, true)
        }


        // Draw AI hand
        write_at(54, 13, "COMPUTER")
        #partial switch p_game_state.player_2_hand {
            case .Rock:    draw_rock_at(50, 14, false)
            case .Paper:   draw_paper_at(45, 14, false)
            case .Scissor: draw_scissor_at(45, 14, false)
        }


        // Draw round outcome
        switch best_of_state.round_state {
            case .Player_1_Win: write_at(34, 22, "You win!")
            case .Player_2_Win: write_at(34, 22, "You lose!")
            case .Draw:         write_at(34, 22, "It's a draw!")
        }

        draw_horizontal_line_at(2, 25, 73, "_")
        if( best_of_state.player_wins == 3 ){
            write_at(3, 27, "You win the game! Press Enter to go back to Main Menu")
        } else if(best_of_state.ai_wins == 3){
            write_at(3, 27, "You lose the game! Press Enter to go back to Main Menu")
        } else {
            write_at(3, 27, "Press Enter to play next round")
        }
        p_game_state.is_drawn = true
    }
}

render_speed_game :: proc(p_game_state: ^Game_State_t) {
    speed_mode_state := p_game_state.game_mode_state.(Speed_Mode_State_t)
    if !p_game_state.is_drawn {
        write_at(0, 1,  " ____________________________________________________________________________")
        write_at(0, 2,  "|                                                                            |")
        write_at(0, 3,  "|                            ROCK, PAPER, SCISSORS                           |")
        write_at(0, 4,  "|____________________________________________________________________________|")
        write_at(0, 5,  "|                                                                            |")
        write_at(0, 6,  "|                                  SPEED                                     |")
        write_at(0, 7,  "|____________________________________________________________________________|")
        write_at(0, 8,  "|                                                                            |")
        write_at(0, 9,  "|     Seconds left:                                     Score:               |")
        write_at(0, 10, "|____________________________________________________________________________|")
        write_at(0, 11, "|                                                                            |")
        write_at(0, 12, "|                                                                            |")
        write_at(0, 13, "|                                                                            |")
        write_at(0, 14, "|                                                                            |")
        write_at(0, 15, "|                                                                            |") 
        write_at(0, 16, "|                                                                            |")
        write_at(0, 17, "|                                                                            |")
        write_at(0, 18, "|                                                                            |")
        write_at(0, 19, "|                                                                            |")
        write_at(0, 20, "|                                                                            |")
        write_at(0, 21, "|                                                                            |")
        write_at(0, 22, "|                                                                            |")
        write_at(0, 23, "|  4. Quit                                                                   |")
        write_at(0, 24, "|                                                                            |")
        write_at(0, 25, "|____________________________________________________________________________|")
        write_at(0, 26, "|                                                                            |")
        write_at(0, 27, "|                                                                            |")
        write_at(0, 28, "|                                                                            |")
        write_at(0, 29, "|                                                                            |")
        write_at(0, 30, "|____________________________________________________________________________|")


        score := fmt.aprintf("%d", speed_mode_state.score)
        write_at(64, 9, score)



        // Draw player hand
        write_at(20, 13, "YOU")
        #partial switch p_game_state.player_1_hand {
            case .Rock:    draw_rock_at(15, 14, true)
            case .Paper:   draw_paper_at(15, 14, true)
            case .Scissor: draw_scissor_at(15, 14, true)
        }


        // Draw AI hand
        write_at(54, 13, "COMPUTER")
        #partial switch p_game_state.player_2_hand {
            case .Rock:    draw_rock_at(50, 14, false)
            case .Paper:   draw_paper_at(45, 14, false)
            case .Scissor: draw_scissor_at(45, 14, false)
        }


        // Draw round outcome
        switch speed_mode_state.round_state {
            case .Player_1_Win: write_at(22, 28, "You win! Press ENTER to continue.")
            case .Player_2_Win: write_at(22, 28, "You lose! Press ENTER to continue.")
            case .Draw:         write_at(22, 28, "It's a draw! Press ENTER to continue.")
        }

        p_game_state.is_drawn = true
    }

    duration := time.stopwatch_duration(speed_mode_state.stopwatch)
    seconds  := 30.0 - time.duration_seconds(duration)
    seconds_left := fmt.aprintf("%.0f ", seconds)

    write_at(21, 9, seconds_left)
}

render_classic_game :: proc(p_game_state: ^Game_State_t) {
    if !p_game_state.is_drawn {
        draw_box_at(0, 1, 76, 30, "_", "_", "|", "|")
        write_at(0, 1, " ")
        write_at(76, 0, " ")
        write_at(30, 3,  "ROCK, PAPER, SCISSORS")
        draw_horizontal_line_at(2, 4, 73, "_")
        write_at(33, 6,  "CLASSIC GAME")
        draw_horizontal_line_at(2, 7, 73, "_")
        draw_horizontal_line_at(2, 25, 73, "_")

        // Draw player hand
        write_at(20, 12, "YOU")
        #partial switch p_game_state.player_1_hand {
            case .Rock:    draw_rock_at(15, 13, true)
            case .Paper:   draw_paper_at(15, 13, true)
            case .Scissor: draw_scissor_at(15, 13, true)
        }

        // Draw AI hand
        write_at(54, 12, "COMPUTER")
        #partial switch p_game_state.player_2_hand {
            case .Rock:    draw_rock_at(50, 13, false)
            case .Paper:   draw_paper_at(45, 13, false)
            case .Scissor: draw_scissor_at(45, 13, false)
        }

        // Draw round outcome
        switch p_game_state.game_mode_state.(Round_State_e) {
            case .Player_1_Win: write_at(34, 22, "You win!")
            case .Player_2_Win: write_at(34, 22, "You lose!")
            case .Draw:         write_at(34, 22, "It's a draw!")
        }

        write_at(3, 27, "Press Enter to go back to Main Menu...")
        p_game_state.is_drawn = true
    }
}

render_best_of_selection :: proc(p_game_state: ^Game_State_t) {
    if !p_game_state.is_drawn {
        write_at(0, 1,  " ____________________________________________________________________________")
        write_at(0, 2,  "|                                                                            |")
        write_at(0, 3,  "|                            ROCK, PAPER, SCISSORS                           |")
        write_at(0, 4,  "|____________________________________________________________________________|")
        write_at(0, 5,  "|                                                                            |")
        write_at(0, 6,  "|                              BEST OUT OF FIVE                              |")
        write_at(0, 7,  "|____________________________________________________________________________|")
        write_at(0, 8,  "|                                                                            |")
        write_at(0, 9,  "|                                                                            |")
        write_at(0, 10, "|  Choose your move:                                                         |")
        write_at(0, 11, "|                                                                            |")
        write_at(0, 12, "|       1. Rock               2. Paper              3. Scissors              |")
        write_at(0, 13, "|            _______             _______                _______              |") 
        write_at(0, 14, "|        ---'   ____)        ---'    ____)____      ---'   ____)____         |")
        write_at(0, 15, "|              (_____)                  ______)               ______)        |")
        write_at(0, 16, "|              (_____)                 _______)            __________)       |")
        write_at(0, 17, "|              (____)                 _______)            (____)             |")
        write_at(0, 18, "|        ---.__(___)         ---.__________)        ---.__(___)              |")
        write_at(0, 19, "|                                                                            |")
        write_at(0, 20, "|                                                                            |")
        write_at(0, 21, "|                                                                            |")
        write_at(0, 22, "|                                                                            |")
        write_at(0, 23, "|  4. Quit                                                                   |")
        write_at(0, 24, "|                                                                            |")
        write_at(0, 25, "|____________________________________________________________________________|")
        write_at(0, 26, "|                                                                            |")
        write_at(0, 27, "| Please enter the number of the move you would like to play:                |")
        write_at(0, 28, "|                                                                            |")
        write_at(0, 29, "| >                                                                          |")
        write_at(0, 30, "|____________________________________________________________________________|")
        p_game_state.is_drawn = true
    }

    // TODO[Jeppe]: Fix issue with deleting input if 5 is pressed.
    input_field := p_game_state.input_field
    if input_field.value > 0 && input_field.value < 5 {
        value := fmt.aprintf("%d", input_field.value)
		write_at(5, 29, value)
    } else {
        write_at(5, 29, " ")
    }
}

render_speed_selection :: proc(p_game_state: ^Game_State_t) {
    if !p_game_state.is_drawn {
        fmt.printf("\x1b[2J")
        write_at(0, 1,  " ____________________________________________________________________________")
        write_at(0, 2,  "|                                                                            |")
        write_at(0, 3,  "|                            ROCK, PAPER, SCISSORS                           |")
        write_at(0, 4,  "|____________________________________________________________________________|")
        write_at(0, 5,  "|                                                                            |")
        write_at(0, 6,  "|                                  SPEED                                     |")
        write_at(0, 7,  "|____________________________________________________________________________|")
        write_at(0, 8,  "|                                                                            |")
        write_at(0, 9,  "|     Seconds left:                                     Score:               |")
        write_at(0, 10, "|____________________________________________________________________________|")
        write_at(0, 11, "|                                                                            |")
        write_at(0, 12, "|  Choose your move:                                                         |")
        write_at(0, 13, "|                                                                            |")
        write_at(0, 14, "|       1. Rock               2. Paper              3. Scissors              |")
        write_at(0, 15, "|            _______             _______                _______              |") 
        write_at(0, 16, "|        ---'   ____)        ---'    ____)____      ---'   ____)____         |")
        write_at(0, 17, "|              (_____)                  ______)               ______)        |")
        write_at(0, 18, "|              (_____)                 _______)            __________)       |")
        write_at(0, 19, "|              (____)                 _______)            (____)             |")
        write_at(0, 20, "|        ---.__(___)         ---.__________)        ---.__(___)              |")
        write_at(0, 21, "|                                                                            |")
        write_at(0, 22, "|                                                                            |")
        write_at(0, 23, "|  4. Quit                                                                   |")
        write_at(0, 24, "|                                                                            |")
        write_at(0, 25, "|____________________________________________________________________________|")
        write_at(0, 26, "|                                                                            |")
        write_at(0, 27, "| Please enter the number of the move you would like to play:                |")
        write_at(0, 28, "|                                                                            |")
        write_at(0, 29, "| >                                                                          |")
        write_at(0, 30, "|____________________________________________________________________________|")
        p_game_state.is_drawn = true
    }

    speed_mode_state := p_game_state.game_mode_state.(Speed_Mode_State_t)
    duration := time.stopwatch_duration(speed_mode_state.stopwatch)
    seconds  := 30.0 - time.duration_seconds(duration)
    seconds_left := fmt.aprintf("%.0f ", seconds)
    score := fmt.aprintf("%d", speed_mode_state.score)

    write_at(21, 9, seconds_left)
    write_at(64, 9, score)

    // TODO[Jeppe]: Fix issue with deleting input if 5 is pressed.
    input_field := p_game_state.input_field
    if input_field.value > 0 && input_field.value < 5 {
        value := fmt.aprintf("%d", input_field.value)
		write_at(5, 29, value)
    } else {
        write_at(5, 29, " ")
    }
}

render_speed_end :: proc(p_game_state: ^Game_State_t) {
    if !p_game_state.is_drawn {
        write_at(0, 1,  " ____________________________________________________________________________")
        write_at(0, 2,  "|                                                                            |")
        write_at(0, 3,  "|                            ROCK, PAPER, SCISSORS                           |")
        write_at(0, 4,  "|____________________________________________________________________________|")
        write_at(0, 5,  "|                                                                            |")
        write_at(0, 6,  "|                                  SPEED                                     |")
        write_at(0, 7,  "|____________________________________________________________________________|")
        write_at(0, 8,  "|                                                                            |")
        write_at(0, 9,  "|                                                                            |")
        write_at(0, 10, "|                               Times up!                                    |")
        write_at(0, 11, "|                                                                            |")
        write_at(0, 12, "|                                                                            |")
        write_at(0, 13, "|                                                                            |")
        write_at(0, 14, "|                                                                            |")
        write_at(0, 15, "|                          SCORE:                                            |") 
        write_at(0, 16, "|                                                                            |")
        write_at(0, 17, "|                                                                            |")
        write_at(0, 18, "|                                                                            |")
        write_at(0, 19, "|                                                                            |")
        write_at(0, 20, "|                                                                            |")
        write_at(0, 21, "|                                                                            |")
        write_at(0, 22, "|                                                                            |")
        write_at(0, 23, "|                                                                            |")
        write_at(0, 24, "|                                                                            |")
        write_at(0, 25, "|____________________________________________________________________________|")
        write_at(0, 26, "|                                                                            |")
        write_at(0, 27, "| Press enter to go to the main menu                                         |")
        write_at(0, 28, "|                                                                            |")
        write_at(0, 29, "|                                                                            |")
        write_at(0, 30, "|____________________________________________________________________________|")
    
        speed_mode_state := p_game_state.game_mode_state.(Speed_Mode_State_t)
        score := fmt.aprintf("%d", speed_mode_state.score)
        write_at(35, 15, score)
        p_game_state.is_drawn = true
    }
}


render_classic_selection :: proc(p_game_state: ^Game_State_t) {
    if !p_game_state.is_drawn {
        write_at(0, 1,  " ____________________________________________________________________________")
        write_at(0, 2,  "|                                                                            |")
        write_at(0, 3,  "|                            ROCK, PAPER, SCISSORS                           |")
        write_at(0, 4,  "|____________________________________________________________________________|")
        write_at(0, 5,  "|                                                                            |")
        write_at(0, 6,  "|                               CLASSIC GAME                                 |")
        write_at(0, 7,  "|____________________________________________________________________________|")
        write_at(0, 8,  "|                                                                            |")
        write_at(0, 9,  "|                                                                            |")
        write_at(0, 10, "|  Choose your move:                                                         |")
        write_at(0, 11, "|                                                                            |")
        write_at(0, 12, "|       1. Rock               2. Paper              3. Scissors              |")
        write_at(0, 13, "|            _______             _______                _______              |")
        write_at(0, 14, "|        ---'   ____)        ---'    ____)____      ---'   ____)____         |")
        write_at(0, 15, "|              (_____)                  ______)               ______)        |")
        write_at(0, 16, "|              (_____)                 _______)            __________)       |")
        write_at(0, 17, "|              (____)                 _______)            (____)             |")
        write_at(0, 18, "|        ---.__(___)         ---.__________)        ---.__(___)              |")
        write_at(0, 19, "|                                                                            |")
        write_at(0, 20, "|                                                                            |")
        write_at(0, 21, "|                                                                            |")
        write_at(0, 22, "|                                                                            |")
        write_at(0, 23, "|  4. Quit                                                                   |")
        write_at(0, 24, "|                                                                            |")
        write_at(0, 25, "|____________________________________________________________________________|")
        write_at(0, 26, "|                                                                            |")
        write_at(0, 27, "| Please enter the number of the move you would like to play:                |")
        write_at(0, 28, "|                                                                            |")
        write_at(0, 29, "| >                                                                          |")
        write_at(0, 30, "|____________________________________________________________________________|")
        p_game_state.is_drawn = true
    }

    // TODO[Jeppe]: Fix issue with deleting input if 5 is pressed.
    input_field := p_game_state.input_field
    if input_field.value > 0 && input_field.value < 5 {
        value := fmt.aprintf("%d", input_field.value)
		write_at(5, 29, value)
    } else {
        write_at(5, 29, " ")
    }
}

draw_rock_at :: proc(x: int, y: int, face_left: bool) {
    if face_left {
        write_at(x, y,   "    _______")
        write_at(x, y+1, "---'   ____)")
        write_at(x, y+2, "      (_____)")
        write_at(x, y+3, "      (_____)")
        write_at(x, y+4, "      (____) ")
        write_at(x, y+5, "---.__(___)  ")
    } else {
        write_at(x, y,   "  _______    ")
        write_at(x, y+1, " (____   '---")
        write_at(x, y+2, "(_____)      ")
        write_at(x, y+3, "(_____)      ")
        write_at(x, y+4, " (____)      ")
        write_at(x, y+5, "  (___)__.---") 
    }
}

draw_paper_at :: proc(x: int, y: int, face_left: bool) {
    if face_left {
        write_at(x, y,   "    _______       ")
        write_at(x, y+1, "---'    ____)____ ")
        write_at(x, y+2, "           ______)")
        write_at(x, y+3, "          _______)")
        write_at(x, y+4, "         _______)")
        write_at(x, y+5, "---.__________)")
    } else {
        write_at(x, y,   "       _______    ")
        write_at(x, y+1, " ____(____    '---")
        write_at(x, y+2, "(______           ")
        write_at(x, y+3, "(_______          ")
        write_at(x, y+4, " (_______         ")
        write_at(x, y+5, "   (__________.---")
    }
}

draw_scissor_at :: proc(x: int, y: int, face_left: bool) {
    if face_left {
        write_at(x, y,   "    _______       ")
        write_at(x, y+1, "---'   ____)____  ")
        write_at(x, y+2, "          ______) ")
        write_at(x, y+3, "       __________)")
        write_at(x, y+4, "      (____)      ")
        write_at(x, y+5, "---.__(___)       ")
    } else {
        write_at(x, y,   "       _______    ")
        write_at(x, y+1, "  ____(____   '---")
        write_at(x, y+2, " (______          ")
        write_at(x, y+3, "(__________       ")
        write_at(x, y+4, "      (____)      ")
        write_at(x, y+5, "       (___)__.---")
    }
}


write_at :: proc(x: int, y: int, text: string) {
    fmt.printf("\x1b[%d;%dH%s", y, x, text)
}

draw_box_at :: proc(x: int, y: int, width: u16, height: u16, top: string, bottom: string, left: string, right: string) {
    for i in cast(u16)x..=(cast(u16)x + width) {
        write_at(cast(int)i, y, top )
        write_at(cast(int)i, y + cast(int)height, bottom )
    }

     for j in cast(u16)y..=(cast(u16)y + height) {
        write_at(x, cast(int)j, left )
        write_at(x + cast(int)width, cast(int)j, right )
    }
}

draw_horizontal_line_at :: proc(x: int, y: int, width: u16, symbol: string) {
    for i in cast(u16)x..=(cast(u16)x + width) {
        write_at(cast(int)i, y, symbol )
    }
}