package game_scene

import "core:fmt"
import "core:math/rand"


import "hgl:terminal"
import "hgl:event"

import ctx "../context"

import "../field"

// TODO[Jeppe]: Clean this up

Input_Submit_Event_t :: struct {
    p_input_field: ^field.U8_InputField_t,
    p_scene: ^Classic_Game_Scene,
}

Input_Enter_Event_t :: struct {
    p_input_field: ^field.Enter_InputField_t,
}

Show_Hands_Event_t :: struct {
    move: u8,
    p_scene: ^Classic_Game_Scene,
}

Classic_Game_Scene_State_e :: enum {
    Select_Move,
    Show_Hands,
}

Round_State_e :: enum {
    Win,
    Lose,
    Draw,
}

Classic_Game_State_t :: struct {
    ai_hand:     u8,
    player_hand: u8,
    round_state: Round_State_e,
    scene_state: Classic_Game_Scene_State_e, 
}

Classic_Game_Scene :: struct {
    input_field: field.U8_InputField_t,
    enter_field: field.Enter_InputField_t,
    game_state: Classic_Game_State_t,
}

classic_game_scene_init :: proc(p_game_context: rawptr, p_scene_data: rawptr) {
    p_scene := cast(^Classic_Game_Scene)p_scene_data
    p_scene.input_field = field.create_u8_input_field()
    p_scene.enter_field = field.create_enter_input_field()
}

create_classic_game_state :: proc() -> Classic_Game_State_t {
    ROCK :: 1
    PAPER :: 2
    SCISSORS :: 3
    hands := [3]u8{ROCK, PAPER, SCISSORS}
    return Classic_Game_State_t{ 
        ai_hand     = rand.choice(hands[:]),
        player_hand = 0,
        round_state = nil,
        scene_state = .Select_Move,
    }
}


classic_game_scene_stop :: proc(p_game_context: rawptr, p_scene_data: rawptr) {
    p_game_context := cast(^ctx.Game_Context_t)p_game_context
    p_scene := cast(^Classic_Game_Scene)p_scene_data

    field.reset_u8_input_field(&p_scene.input_field)
    field.reset_enter_input_field(&p_scene.enter_field)

    terminal.win_terminal_unregister_key_callback(p_game_context.p_terminal)
	event.unregister_handler(p_game_context.p_event_dispatcher, "INPUT_ENTER_EVENT")
    event.unregister_handler(p_game_context.p_event_dispatcher, "INPUT_SUBMIT_EVENT")
    event.unregister_handler(p_game_context.p_event_dispatcher, "SHOW_HANDS_EVENT")


    terminal.write_at(15, 10, "IN STOP - CLASSIC")
}

classic_game_scene_start :: proc(p_game_context: rawptr, p_scene_data: rawptr) {
    p_game_context := cast(^ctx.Game_Context_t)p_game_context
    p_scene := cast(^Classic_Game_Scene)p_scene_data

    terminal.win_terminal_register_key_callback(p_game_context.p_terminal, field.handle_key_event, &p_scene.input_field)
	event.register_handler(p_game_context.p_event_dispatcher, "INPUT_SUBMIT_EVENT", classic_game_input_submit_event_handler)
    event.register_handler(p_game_context.p_event_dispatcher, "SHOW_HANDS_EVENT", classic_game_show_hands_event_handler)

    p_scene.game_state = create_classic_game_state()

}

classic_game_scene_render :: proc(p_game_context: rawptr, p_scene_data: rawptr) {
    p_game_context := cast(^ctx.Game_Context_t)p_game_context
    p_scene := cast(^Classic_Game_Scene)p_scene_data
    game_state := p_scene.game_state
    
    if game_state.scene_state == .Select_Move {
        terminal.write_at(0, 1,  " ____________________________________________________________________________")
        terminal.write_at(0, 2,  "|                                                                            |")
        terminal.write_at(0, 3,  "|                            ROCK, PAPER, SCISSORS                           |")
        terminal.write_at(0, 4,  "|____________________________________________________________________________|")
        terminal.write_at(0, 5,  "|                                                                            |")
        terminal.write_at(0, 6,  "|                               CLASSIC GAME                                 |")
        terminal.write_at(0, 7,  "|____________________________________________________________________________|")
        terminal.write_at(0, 8,  "|                                  _______                                   |")
        terminal.write_at(0, 9,  "|                              ---'   ____)                                  |")
        terminal.write_at(0, 10, "|                                    (_____)                                 |")
        terminal.write_at(0, 11, "|                                    (_____)                                 |")
        terminal.write_at(0, 12, "|                                    (____)                                  |")
        terminal.write_at(0, 13, "|                              ---.__(___)                                   |")
        terminal.write_at(0, 14, "|  Choose your move:                                                         |")
        terminal.write_at(0, 15, "|                                                                            |")
        terminal.write_at(0, 16, "|       1. Rock               2. Paper              3. Scissors              |")
        terminal.write_at(0, 17, "|            _______             _______                _______              |")
        terminal.write_at(0, 18, "|        ---'   ____)        ---'    ____)____      ---'   ____)____         |")
        terminal.write_at(0, 19, "|              (_____)                  ______)               ______)        |")
        terminal.write_at(0, 20, "|              (_____)                 _______)            __________)       |")
        terminal.write_at(0, 21, "|              (____)                 _______)            (____)             |")
        terminal.write_at(0, 22, "|        ---.__(___)         ---.__________)        ---.__(___)              |")
        terminal.write_at(0, 23, "|                                                                            |")
        terminal.write_at(0, 24, "| 4. Quit                                                                    |")
        terminal.write_at(0, 25, "|____________________________________________________________________________|")
        terminal.write_at(0, 26, "|                                                                            |")
        terminal.write_at(0, 27, "| Please enter the number of the move you would like to play:                |")
        terminal.write_at(0, 28, "|                                                                            |")
        terminal.write_at(0, 29, "| >                                                                          |")
        terminal.write_at(0, 30, "|____________________________________________________________________________|")
    
            
        input_field := p_scene.input_field
        if input_field.value > 0 && input_field.value < 5 {
            // TODO[Jeppe]: Fix this.
            value := fmt.aprintf("%d", input_field.value)
            terminal.write_at(5, 29, value)
        } else {
            terminal.delete_at(5, 29)
        }
    
    }


    if game_state.scene_state == .Show_Hands {
        draw_scene_outline()

        // Draw player hand
        terminal.write_at(20, 12, "YOU")
        if game_state.player_hand == 1 {
            draw_rock_at(15, 13, true)
        } else if game_state.player_hand == 2 {
            draw_paper_at(15, 13, true)
        } else {
            draw_scissor_at(15, 13, true)
        }

        // Draw AI hand
        terminal.write_at(54, 12, "COMPUTER")
        if game_state.ai_hand == 1 {
            draw_rock_at(50, 13, false)
        } else if game_state.ai_hand == 2 {
            draw_paper_at(45, 13, false)
        } else {
            draw_scissor_at(45, 13, false)
        }


        switch game_state.round_state {
            case .Win: terminal.write_at(34, 22, "You win!")
            case .Lose: terminal.write_at(34, 22, "You lose!")
            case .Draw: terminal.write_at(34, 22, "It's a draw!")
        }


        terminal.write_at(3, 27, "Press Enter to go back to Main Menu...")

    }
}

draw_rock_at :: proc(x: int, y: int, face_left: bool) {
    if face_left {
        terminal.write_at(x, y,   "    _______")
        terminal.write_at(x, y+1, "---'   ____)")
        terminal.write_at(x, y+2, "      (_____)")
        terminal.write_at(x, y+3, "      (_____)")
        terminal.write_at(x, y+4, "      (____) ")
        terminal.write_at(x, y+5, "---.__(___)  ")
    } else {
        terminal.write_at(x, y,   "  _______    ")
        terminal.write_at(x, y+1, " (____   '---")
        terminal.write_at(x, y+2, "(_____)      ")
        terminal.write_at(x, y+3, "(_____)      ")
        terminal.write_at(x, y+4, " (____)      ")
        terminal.write_at(x, y+5, "  (___)__.---") 
    }
}

draw_paper_at :: proc(x: int, y: int, face_left: bool) {
    if face_left {
        terminal.write_at(x, y,   "    _______       ")
        terminal.write_at(x, y+1, "---'    ____)____ ")
        terminal.write_at(x, y+2, "           ______)")
        terminal.write_at(x, y+3, "          _______)")
        terminal.write_at(x, y+4, "         _______)")
        terminal.write_at(x, y+5, "---.__________)")
    } else {
        terminal.write_at(x, y,   "       _______    ")
        terminal.write_at(x, y+1, " ____(____    '---")
        terminal.write_at(x, y+2, "(______           ")
        terminal.write_at(x, y+3, "(_______          ")
        terminal.write_at(x, y+4, " (_______         ")
        terminal.write_at(x, y+5, "   (__________.---")
    }
}

draw_scissor_at :: proc(x: int, y: int, face_left: bool) {
    if face_left {
        terminal.write_at(x, y,   "    _______       ")
        terminal.write_at(x, y+1, "---'   ____)____  ")
        terminal.write_at(x, y+2, "          ______) ")
        terminal.write_at(x, y+3, "       __________)")
        terminal.write_at(x, y+4, "      (____)      ")
        terminal.write_at(x, y+5, "---.__(___)       ")
    } else {
        terminal.write_at(x, y,   "       _______    ")
        terminal.write_at(x, y+1, "  ____(____   '---")
        terminal.write_at(x, y+2, " (______          ")
        terminal.write_at(x, y+3, "(__________       ")
        terminal.write_at(x, y+4, "      (____)      ")
        terminal.write_at(x, y+5, "       (___)__.---")
    }
}

draw_scene_outline :: proc() {
    terminal.draw_box_at(0, 1, 76, 30, "_", "_", "|", "|")
    terminal.write_at(0, 1, " ")
    terminal.write_at(76, 0, " ")
    terminal.write_at(30, 3,  "ROCK, PAPER, SCISSORS")
    terminal.draw_horizontal_line_at(2, 4, 73, "_")
    terminal.write_at(33, 6,  "CLASSIC GAME")
    terminal.draw_horizontal_line_at(2, 7, 73, "_")
    terminal.draw_horizontal_line_at(2, 25, 73, "_")

}

classic_game_scene_update :: proc(p_game_context: rawptr, p_scene_data: rawptr) {
	p_game_context := cast(^ctx.Game_Context_t)p_game_context
    p_scene := cast(^Classic_Game_Scene)p_scene_data
    game_state := p_scene.game_state


    if game_state.scene_state == .Select_Move {
        input_field := p_scene.input_field
        if input_field.is_submitted {
            event_data := Input_Submit_Event_t { p_input_field = &input_field, p_scene = p_scene}
            event.dispatch_event(p_game_context.p_event_dispatcher, "INPUT_SUBMIT_EVENT", &event_data, p_game_context)
        }
    } else {
        enter_field := p_scene.enter_field
        if enter_field.is_submitted {
            event_data := Input_Enter_Event_t { p_input_field = &enter_field}
            event.dispatch_event(p_game_context.p_event_dispatcher, "INPUT_ENTER_EVENT", &event_data, p_game_context)
        }
    }


}


classic_game_input_submit_event_handler :: proc(p_game_context: rawptr, p_event_data: rawptr) {
	p_game_context := cast(^ctx.Game_Context_t)p_game_context
	p_event_data := cast(^Input_Submit_Event_t)p_event_data
    p_input_field := p_event_data.p_input_field

    QUIT :: 4
	if p_input_field.value == QUIT {
		event.dispatch_event(p_game_context.p_event_dispatcher, "QUIT_EVENT", nil, p_game_context)
	} else {
        event_data := Show_Hands_Event_t { move = p_input_field.value, p_scene = p_event_data.p_scene}
        event.dispatch_event(p_game_context.p_event_dispatcher, "SHOW_HANDS_EVENT", &event_data, p_game_context)
    }

    field.reset_u8_input_field(p_input_field)
}

classic_game_input_enter_event_handler :: proc(p_game_context: rawptr, p_event_data: rawptr) {
	p_game_context := cast(^ctx.Game_Context_t)p_game_context
	p_event_data := cast(^Input_Enter_Event_t)p_event_data
    p_input_field := p_event_data.p_input_field
    field.reset_enter_input_field(p_input_field)


    scene := "Main Menu"
	event.dispatch_event(p_game_context.p_event_dispatcher, "CHANGE_SCENE_EVENT", &scene, p_game_context)

}


classic_game_show_hands_event_handler :: proc(p_game_context: rawptr, p_event_data: rawptr) {
    p_game_context := cast(^ctx.Game_Context_t)p_game_context
    p_event_data := cast(^Show_Hands_Event_t)p_event_data
    p_scene := p_event_data.p_scene
    p_game_state := &p_scene.game_state

    terminal.win_terminal_unregister_key_callback(p_game_context.p_terminal)
	event.unregister_handler(p_game_context.p_event_dispatcher, "INPUT_SUBMIT_EVENT")
    event.unregister_handler(p_game_context.p_event_dispatcher, "SHOW_HANDS_EVENT")

    terminal.win_terminal_register_key_callback(p_game_context.p_terminal, field.handle_enter_field_key_event, &p_scene.enter_field)
    event.register_handler(p_game_context.p_event_dispatcher, "INPUT_ENTER_EVENT", classic_game_input_enter_event_handler)


    outcomes := [3][3]Round_State_e{
	    {.Draw, .Lose, .Win},
		{.Win, .Draw, .Lose},
		{.Lose, .Win, .Draw},
	}

    p_game_state.scene_state = .Show_Hands
    p_game_state.player_hand = p_event_data.move
    p_game_state.round_state = outcomes[p_game_state.player_hand - 1][p_game_state.ai_hand - 1]

    terminal.clear()
}