package main

import "core:fmt"
import "core:math/rand"
import "core:time"
import win "core:sys/windows"

import local_win "windows"


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
}

Speed_Mode_State_t :: struct {
    score: int,
    stopwatch: time.Stopwatch,
    is_over: bool,
}

Game_State_t :: struct {
    game_mode:  Game_Mode_e,
    game_mode_state: union {
        Best_Of_Mode_State_t,
        Speed_Mode_State_t,
    }

    player_1_hand: Hand_e,
    player_2_hand: Hand_e,
    round_state:   Round_State_e,
    input_field:   Input_field_t,
    is_drawn:      bool,

}

select_hand :: proc "contextless" (p_input_field: ^Input_field_t) -> Hand_e {
    result: Hand_e = .None
    switch p_input_field.value {
        case 1: result = .Rock
        case 2: result = .Paper
        case 3: result = .Scissor
    }
    reset_input_field(p_input_field)
    return result
}


select_hand_option :: proc "contextless" (p_input_field: ^Input_field_t) -> (bool, Hand_e) {
    is_submitted := false
    hand: Hand_e = .None
    if p_input_field.is_submitted && p_input_field.value > 0 && p_input_field.value < 5 {
        switch p_input_field.value {
            case 1: hand = .Rock
            case 2: hand = .Paper
            case 3: hand = .Scissor
        }
        is_submitted = true
        reset_input_field(p_input_field)
    }
    return is_submitted, hand;
}

reset_round :: proc "contextless" (p_game_state: ^Game_State_t) {
    p_game_state.is_drawn      = false
    p_game_state.player_1_hand = .None
    p_game_state.player_2_hand = .None
    p_game_state.round_state   = nil
    reset_input_field(&p_game_state.input_field)
}

reset_game :: proc "contextless" (p_game_state: ^Game_State_t) {
    p_game_state.is_drawn      = false
    p_game_state.game_mode     = .None
    p_game_state.player_1_hand = .None
    p_game_state.player_2_hand = .None
    p_game_state.round_state   = nil
    reset_input_field(&p_game_state.input_field)
}

reset_input_field :: proc "contextless" (p_input_field: ^Input_field_t) {
    p_input_field.value        = 0
    p_input_field.is_submitted = false
}

handle_input_events :: proc "contextless" (input_handle: win.HANDLE, p_input_field: ^Input_field_t) {
    num_events: win.DWORD = 0
    if( !local_win.GetNumberOfConsoleInputEvents(input_handle, &num_events)){
        // TODO[Jeppe]: Logging
        return 
    }
    events_read: u32 = 0
    input_records: [64]local_win.INPUT_RECORD
    if(!local_win.ReadConsoleInputW(input_handle, &input_records[0], num_events, &events_read)){
        // TODO[Jeppe]: Logging
        return
    }

    for input_record in input_records {
        switch(input_record.EventType){
            case local_win.KEY_EVENT:
                key_event := input_record.Event.KeyEvent
                if key_event.bKeyDown {
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

play_round :: proc "contextless" (player_1_hand: Hand_e, player_2_hand: Hand_e) -> Round_State_e {
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


    draw_game_outline()

    // Game loop
    is_app_running := true
    for is_app_running {
        handle_input_events(input_handle, &game_state.input_field)

        #partial switch game_state.game_mode {

            case .None: // Main menu
                render_main_menu(&game_state)
                p_input_field := &game_state.input_field
                if p_input_field.is_submitted && p_input_field.value > 0 && p_input_field.value < 6 {
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

                        case 4: game_state.game_mode = .Multiplayer

                        case 5: is_app_running = false
                    }
                    reset_input_field(p_input_field)
                }


            case .Classic:
                if game_state.player_1_hand == .None {
                    render_classic_selection(&game_state)
                    is_submitted, hand_opt := select_hand_option(&game_state.input_field)
                    if is_submitted {
                        if hand_opt != .None {
                            game_state.player_1_hand = hand_opt
                        } else {
                            game_state.game_mode = .None
                        }
                        game_state.is_drawn = false
                    }
                } else {
                    if game_state.player_2_hand == .None {
                        game_state.player_2_hand = get_random_hand()
                        game_state.round_state = play_round(game_state.player_1_hand, game_state.player_2_hand)
                    }
                    render_classic_game(&game_state)
                    if game_state.input_field.is_submitted {
                        reset_game(&game_state)
                    }
                }

            case .Best_Of:
                if game_state.player_1_hand == .None {
                    render_best_of_selection(&game_state)
                    is_submitted, hand_opt := select_hand_option(&game_state.input_field)
                    if is_submitted {
                        if hand_opt != .None {
                            game_state.player_1_hand = hand_opt
                        } else {
                            game_state.game_mode = .None
                        }
                        game_state.is_drawn = false
                    }
                } else {
                    p_best_of_state := &game_state.game_mode_state.(Best_Of_Mode_State_t)
                    if game_state.player_2_hand == .None {
                        game_state.player_2_hand = get_random_hand()
                        game_state.round_state = play_round(game_state.player_1_hand, game_state.player_2_hand)
                        switch game_state.round_state {
                            case .Player_1_Win: p_best_of_state.player_wins += 1
                            case .Player_2_Win: p_best_of_state.ai_wins += 1
                            case .Draw:     
                        }
                        reset_input_field(&game_state.input_field)
                        game_state.is_drawn = false
                    } 
                    
                    if game_state.player_2_hand != .None {
                        render_best_of_game(&game_state)
                        if game_state.input_field.is_submitted {
                            reset_round(&game_state)
                            if( p_best_of_state.player_wins >= 3 || p_best_of_state.ai_wins >= 3) {
                                game_state.game_mode = .None
                            }

           
                        }
                    }
                }

            case .Speed:
                p_speed_state := &game_state.game_mode_state.(Speed_Mode_State_t)
                duration := time.stopwatch_duration(p_speed_state.stopwatch)
                seconds  := time.duration_seconds(duration)
                if seconds <= 30.0 {
                    if game_state.player_1_hand == .None {
                        render_speed_selection(&game_state)
                        is_submitted, hand_opt := select_hand_option(&game_state.input_field)
                        if is_submitted {
                            if hand_opt != .None {
                                game_state.player_1_hand = hand_opt
                            } else {
                                game_state.game_mode = .None
                            }
                            game_state.is_drawn = false
                        }
                    } else {
                        if game_state.player_2_hand == .None {
                            game_state.player_2_hand = get_random_hand()
                            game_state.round_state = play_round(game_state.player_1_hand, game_state.player_2_hand)
                            switch game_state.round_state {
                                case .Player_1_Win: p_speed_state.score += 1
                                case .Player_2_Win: p_speed_state.score -= 1
                                case .Draw:     
                            }
                            reset_input_field(&game_state.input_field)
                            game_state.is_drawn = false
                        } 
                    
                        if game_state.player_2_hand != .None {
                            render_speed_game(&game_state)
                            if game_state.input_field.is_submitted {
                                reset_round(&game_state)
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
                        reset_game(&game_state)
                    }
                }
            case .Multiplayer:
                if game_state.player_1_hand == .None {
                        render_multiplayer_selection_player(&game_state, true)
                        is_submitted, hand_opt := select_hand_option(&game_state.input_field)
                        if is_submitted {
                            if hand_opt != .None {
                                game_state.player_1_hand = hand_opt
                            } else {
                                game_state.game_mode = .None
                            }
                            game_state.is_drawn = false
                        }
                }

                if game_state.player_2_hand == .None {
                    render_multiplayer_selection_player(&game_state, false)
                    is_submitted, hand_opt := select_hand_option(&game_state.input_field)
                    if is_submitted {
                        if hand_opt != .None {
                            game_state.player_2_hand = hand_opt
                        } else {
                            game_state.game_mode = .None
                        }
                        game_state.round_state = play_round(game_state.player_1_hand, game_state.player_2_hand)
                        game_state.is_drawn = false
                    }
                }

                if game_state.player_1_hand != .None && game_state.player_2_hand != .None {
                    render_multiplayer_game(&game_state)
                    if game_state.input_field.is_submitted {
                        reset_game(&game_state)
                    }
                }
                
        }
    }
    
    // Alternate buffer end
    fmt.printf("\x1b[?1049l") 
}


render_main_menu :: proc(p_game_state: ^Game_State_t) {
    if !p_game_state.is_drawn {
        reset_game_outline()
        
        // Title
        write_at(35, 6, "GAME MODES")

        // Menu
        write_at(3, 9,  "1. Classic Game")
        write_at(3, 10, "   - Play the classic Rock, Paper, Scissors game against the computer.")

        write_at(3, 12, "2. Best of Five")
        write_at(3, 13, "   - Play a series of 5 games against the computer.")
        write_at(3, 14, "   - The first player to win 3 games is the winner.")

        write_at(3, 16, "3. Time Attack")
        write_at(3, 17, "   - Play against the clock and try to get the highest score possible.")
        write_at(3, 18, "   - Each correct guess earns you points.")
        write_at(3, 19, "   - Incorrect guesses deduct points from your score.")

        write_at(3, 21, "4. Multiplayer")
        write_at(3, 22, "   - Play against a friend on the same computer.")

        write_at(3, 24, "5. Quit") 

        // Input
        write_at(3, 27, "Please enter the number of the game mode you would like to play:")
        write_at(3, 29, ">")

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

render_classic_selection :: proc(p_game_state: ^Game_State_t) {
    if !p_game_state.is_drawn {
        reset_game_outline()

        // Title
        write_at(35, 6, "CLASSIC")

        // Body
        draw_hand_selection()

        p_game_state.is_drawn = true
    }

    input_field := p_game_state.input_field
    if input_field.value > 0 && input_field.value < 5 {
        value := fmt.aprintf("%d", input_field.value)
		write_at(5, 29, value)
    } else if input_field.value == 0 {
        write_at(5, 29, " ")
    }
}

render_classic_game :: proc(p_game_state: ^Game_State_t) {
    if !p_game_state.is_drawn {
        reset_game_outline()

        // Title
        write_at(35, 6,  "CLASSIC")

        draw_show_hands(p_game_state.player_1_hand, p_game_state.player_2_hand, p_game_state.round_state)

        write_at(3, 27, "Press Enter to go back to Main Menu...")
        p_game_state.is_drawn = true
    }
}

render_best_of_selection :: proc(p_game_state: ^Game_State_t) {
    if !p_game_state.is_drawn {
        reset_game_outline()

        // Title
        write_at(32, 6, "BEST OUT OF FIVE")

        // Score
        best_of_state := p_game_state.game_mode_state.(Best_Of_Mode_State_t)
        player_score := fmt.aprintf("Player Score: %d", best_of_state.player_wins)
        computer_score := fmt.aprintf("Computer Score: %d", best_of_state.ai_wins)

        write_at(15, 9, player_score)
        write_at(45, 9, computer_score)
        write_at(2, 10, "____________________________________________________________________________")

        // Body
        draw_hand_selection()

        p_game_state.is_drawn = true
    }

    input_field := p_game_state.input_field
    if input_field.value > 0 && input_field.value < 5 {
        value := fmt.aprintf("%d", input_field.value)
		write_at(5, 29, value)
    } else if input_field.value == 0 {
        write_at(5, 29, " ")
    }
}

render_best_of_game :: proc(p_game_state: ^Game_State_t) {
    if !p_game_state.is_drawn {
        reset_game_outline()

        // Title
        write_at(32, 6,  "BEST OUT OF FIVE")

        // Score
        best_of_state := p_game_state.game_mode_state.(Best_Of_Mode_State_t)
        player_score := fmt.aprintf("Player Score: %d", best_of_state.player_wins)
        computer_score := fmt.aprintf("Computer Score: %d", best_of_state.ai_wins)

        write_at(15, 9, player_score)
        write_at(45, 9, computer_score)
        write_at(2, 10, "____________________________________________________________________________")

        draw_show_hands(p_game_state.player_1_hand, p_game_state.player_2_hand, p_game_state.round_state)


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

render_speed_selection :: proc(p_game_state: ^Game_State_t) {
    if !p_game_state.is_drawn {
        reset_game_outline()

        // Title
        write_at(36, 6,  "SPEED")

        // Game info
        write_at(7, 9,  "Seconds left:                                     Score:")
        write_at(2, 10, "____________________________________________________________________________")

        // Body
        draw_hand_selection()

        p_game_state.is_drawn = true
    }

    speed_mode_state := p_game_state.game_mode_state.(Speed_Mode_State_t)
    duration := time.stopwatch_duration(speed_mode_state.stopwatch)
    seconds  := 30.0 - time.duration_seconds(duration)
    seconds_left := fmt.aprintf("%.0f ", seconds)
    score := fmt.aprintf("%d", speed_mode_state.score)

    write_at(21, 9, seconds_left)
    write_at(64, 9, score)

    input_field := p_game_state.input_field
    if input_field.value > 0 && input_field.value < 5 {
        value := fmt.aprintf("%d", input_field.value)
		write_at(5, 29, value)
    } else if input_field.value == 0 {
        write_at(5, 29, " ")
    }
}

render_speed_game :: proc(p_game_state: ^Game_State_t) {
    speed_mode_state := p_game_state.game_mode_state.(Speed_Mode_State_t)
    if !p_game_state.is_drawn {
        reset_game_outline()

        // Title
        write_at(36, 6,  "SPEED")

        // Game info
        write_at(7, 9,  "Seconds left:                                     Score:")
        
        duration := time.stopwatch_duration(speed_mode_state.stopwatch)
        seconds  := 30.0 - time.duration_seconds(duration)
        seconds_left := fmt.aprintf("%.0f ", seconds)
        score := fmt.aprintf("%d", speed_mode_state.score)

        write_at(64, 9, score)
        write_at(21, 9, seconds_left)

        write_at(2, 10, "____________________________________________________________________________")

        draw_show_hands(p_game_state.player_1_hand, p_game_state.player_2_hand, p_game_state.round_state)
        write_at(3, 27, "Press ENTER to continue")

        p_game_state.is_drawn = true
    }
}

render_speed_end :: proc(p_game_state: ^Game_State_t) {
    if !p_game_state.is_drawn {
        reset_game_outline()

        // Title
        write_at(36, 6,  "SPEED")

        // Body
        write_at(33, 10, "Times up!")
        write_at(28, 15, "SCORE:") 

        speed_mode_state := p_game_state.game_mode_state.(Speed_Mode_State_t)
        score := fmt.aprintf("%d", speed_mode_state.score)
        write_at(35, 15, score)

        // Input
        write_at(3, 27, "Press enter to go to the main menu")
    

        p_game_state.is_drawn = true
    }
}

render_multiplayer_selection_player :: proc(p_game_state: ^Game_State_t, is_player_1: bool) {
    if !p_game_state.is_drawn {
        reset_game_outline()

        // Title
        write_at(34, 6, "MULTIPLAYER")

        // Body
        draw_hand_selection()

        // Input
        if is_player_1 {
            write_at(3, 27, "Player 1, please enter the number of the move you would like to play.")
        } else {
            write_at(3, 27, "Player 2, please enter the number of the move you would like to play.")
        }

        write_at(3, 28, "The option will be hidden!")

        p_game_state.is_drawn = true
    }

    input_field := p_game_state.input_field
    if input_field.value > 0 && input_field.value < 5 {
		write_at(5, 29, "*")
    } else if input_field.value == 0 {
        write_at(5, 29, " ")
    }
}

render_multiplayer_game :: proc(p_game_state: ^Game_State_t) {
    if !p_game_state.is_drawn {
        reset_game_outline()

        write_at(34, 6,  "MULTIPLAYER")

        // Draw player hand
        write_at(20, 12, "PLAYER 1")
        #partial switch p_game_state.player_1_hand {
            case .Rock:    draw_rock_at(15, 13, true)
            case .Paper:   draw_paper_at(15, 13, true)
            case .Scissor: draw_scissor_at(15, 13, true)
        }

        // Draw AI hand
        write_at(54, 12, "PLAYER 2")
        #partial switch p_game_state.player_2_hand {
            case .Rock:    draw_rock_at(50, 13, false)
            case .Paper:   draw_paper_at(45, 13, false)
            case .Scissor: draw_scissor_at(45, 13, false)
        }

        // Draw round outcome
        switch p_game_state.round_state{
            case .Player_1_Win: write_at(32, 22, "Player 1 win!")
            case .Player_2_Win: write_at(32, 22, "Player 2 win!")
            case .Draw:         write_at(32, 22, "It's a draw!")
        }

        write_at(3, 27, "Press Enter to go back to Main Menu...")
        p_game_state.is_drawn = true
    }
}

draw_game_outline :: proc() {
        write_at(0, 1,  " ____________________________________________________________________________\n"  +
                        "|                                                                            |\n" +
                        "|                            ROCK, PAPER, SCISSORS                           |\n" +
                        "|____________________________________________________________________________|\n" +
                        "|                                                                            |\n" +
                        "|                                                                            |\n" +
                        "|____________________________________________________________________________|\n" +
                        "|                                                                            |\n" +
                        "|                                                                            |\n" +
                        "|                                                                            |\n" +
                        "|                                                                            |\n" +
                        "|                                                                            |\n" +
                        "|                                                                            |\n" +
                        "|                                                                            |\n" +
                        "|                                                                            |\n" +
                        "|                                                                            |\n" +
                        "|                                                                            |\n" +
                        "|                                                                            |\n" +
                        "|                                                                            |\n" +
                        "|                                                                            |\n" +
                        "|                                                                            |\n" +
                        "|                                                                            |\n" +
                        "|                                                                            |\n" +
                        "|                                                                            |\n" +
                        "|____________________________________________________________________________|\n" +
                        "|                                                                            |\n" +
                        "|                                                                            |\n" +
                        "|                                                                            |\n" +
                        "|                                                                            |\n" +
                        "|____________________________________________________________________________|")
}


reset_game_outline :: proc() {
    // Title area
    write_at(2, 5, "                                                                            ")
    write_at(2, 6, "                                                                            ")

    // Body area
    for y := 8; y <= 24; y += 1 {
        write_at(2, y, "                                                                            ")
    } 

    // Input area
    for y := 26; y <= 29; y += 1 {
        write_at(2, y, "                                                                            ")
    } 
}


draw_show_hands :: proc(player_1_hand: Hand_e, player_2_hand: Hand_e, round_state: Round_State_e) {
    write_at(20, 13, "YOU")
    #partial switch player_1_hand {
        case .Rock:    draw_rock_at(15, 14, true)
        case .Paper:   draw_paper_at(15, 14, true)
        case .Scissor: draw_scissor_at(15, 14, true)
    }

    write_at(54, 13, "COMPUTER")
    #partial switch player_2_hand {
        case .Rock:    draw_rock_at(50, 14, false)
        case .Paper:   draw_paper_at(45, 14, false)
        case .Scissor: draw_scissor_at(45, 14, false)
    }

    switch round_state {
        case .Player_1_Win: write_at(34, 22, "You win!")
        case .Player_2_Win: write_at(34, 22, "You lose!")
        case .Draw:         write_at(34, 22, "It's a draw!")
    }
}

draw_hand_selection :: proc() {
    write_at(4, 12, "Choose your move:")

    write_at(9, 14, "1. Rock               2. Paper              3. Scissors")
    write_at(2, 15, "            _______             _______                _______") 
    write_at(2, 16, "        ---'   ____)        ---'    ____)____      ---'   ____)____")
    write_at(2, 17, "              (_____)                  ______)               ______)")
    write_at(2, 18, "              (_____)                 _______)            __________)")
    write_at(2, 19, "              (____)                 _______)            (____)")
    write_at(2, 20, "        ---.__(___)         ---.__________)        ---.__(___)")

    write_at(4, 23, "4. Main menu")

    write_at(3, 27, "Please enter the number of the move you would like to play:")
    write_at(3, 29, ">")
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