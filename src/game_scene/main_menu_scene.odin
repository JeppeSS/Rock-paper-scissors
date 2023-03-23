package game_scene

import "core:fmt"

import "hgl:terminal"
import "hgl:event"

import ctx "../context"

import "../field"


Main_Menu_Scene :: struct {
    input_field: field.U8_InputField_t,
}

main_menu_scene_init :: proc(p_game_context: rawptr, p_scene_data: rawptr) {
    p_scene := cast(^Main_Menu_Scene)p_scene_data
    p_scene.input_field = field.create_u8_input_field()
}

main_menu_scene_start :: proc(p_game_context: rawptr, p_scene_data: rawptr) {
    p_game_context := cast(^ctx.Game_Context_t)p_game_context
    p_scene := cast(^Main_Menu_Scene)p_scene_data

    terminal.win_terminal_register_key_callback(p_game_context.p_terminal, field.handle_key_event, &p_scene.input_field)
	event.register_handler(p_game_context.p_event_dispatcher, "INPUT_SUBMIT_EVENT", main_menu_input_submit_event_handler)
}

main_menu_scene_stop :: proc(p_game_context: rawptr, p_scene_data: rawptr) {
    p_game_context := cast(^ctx.Game_Context_t)p_game_context

    terminal.win_terminal_unregister_key_callback(p_game_context.p_terminal)
	event.unregister_handler(p_game_context.p_event_dispatcher, "INPUT_SUBMIT_EVENT")
}

main_menu_scene_render :: proc(p_game_context: rawptr, p_scene_data: rawptr) {
    p_scene := cast(^Main_Menu_Scene)p_scene_data

    terminal.write_at(0, 1,  " ____________________________________________________________________________")
	terminal.write_at(0, 2,  "|                                                                            |")
    terminal.write_at(0, 3,  "|                            ROCK, PAPER, SCISSORS                           |")
	terminal.write_at(0, 4,  "|____________________________________________________________________________|")
    terminal.write_at(0, 5,  "|                                                                            |")
	terminal.write_at(0, 6,  "|                                GAME MODES                                  |")
	terminal.write_at(0, 7,  "|____________________________________________________________________________|")
    terminal.write_at(0, 8,  "|                                                                            |")
    terminal.write_at(0, 9,  "| 1. Classic Game                                                            |")
    terminal.write_at(0, 10, "|    - Play the classic Rock, Paper, Scissors game against the computer.     |")
    terminal.write_at(0, 11, "|                                                                            |")
    terminal.write_at(0, 12, "| 2. Best of Five                                                            |")
    terminal.write_at(0, 13, "|    - Play a series of 5 games against the computer.                        |")
    terminal.write_at(0, 14, "|    - The first player to win 3 games is the winner.                        |")
    terminal.write_at(0, 15, "|                                                                            |")
    terminal.write_at(0, 16, "| 3. Time Attack                                                             |")
    terminal.write_at(0, 17, "|    - Play against the clock and try to get the highest score possible.     |")
    terminal.write_at(0, 18, "|    - Each correct guess earns you points.                                  |")
    terminal.write_at(0, 19, "|    - Incorrect guesses deduct points from your score.                      |")
    terminal.write_at(0, 20, "|                                                                            |")
    terminal.write_at(0, 21, "| 4. Multiplayer                                                             |")
    terminal.write_at(0, 22, "|    - Play against a friend on the same computer.                           |")
    terminal.write_at(0, 23, "|                                                                            |")
    terminal.write_at(0, 24, "| 5. Quit                                                                    |")  
    terminal.write_at(0, 25, "|____________________________________________________________________________|")
    terminal.write_at(0, 26, "|                                                                            |")
    terminal.write_at(0, 27, "| Please enter the number of the game mode you would like to play:           |")
    terminal.write_at(0, 28, "|                                                                            |")
    terminal.write_at(0, 29, "| >                                                                          |")
    terminal.write_at(0, 30, "|____________________________________________________________________________|")


    input_field := p_scene.input_field
    if input_field.value > 0 && input_field.value < 6 {
        // TODO[Jeppe]: Fix this.
        value := fmt.aprintf("%d", input_field.value)
		terminal.write_at(5, 29, value)
    } else {
        terminal.delete_at(5, 29)
    }
}

main_menu_scene_update :: proc(p_game_context: rawptr, p_scene_data: rawptr) {
	p_game_context := cast(^ctx.Game_Context_t)p_game_context
    p_scene := cast(^Main_Menu_Scene)p_scene_data

    input_field := p_scene.input_field
    if input_field.is_submitted {
        event.dispatch_event(p_game_context.p_event_dispatcher, "INPUT_SUBMIT_EVENT", &input_field, p_game_context)
    }

}

main_menu_input_submit_event_handler :: proc(p_game_context: rawptr, p_event_data: rawptr){
	p_game_context := cast(^ctx.Game_Context_t)p_game_context
	p_input_field := cast(^field.U8_InputField_t)p_event_data

    CLASSIC :: 1
    QUIT :: 5
	if p_input_field.value == QUIT {
		event.dispatch_event(p_game_context.p_event_dispatcher, "QUIT_EVENT", nil, p_game_context)
	} else if p_input_field.value == CLASSIC {
        scene := "CLASSIC GAME"
        event.dispatch_event(p_game_context.p_event_dispatcher, "CHANGE_SCENE_EVENT", &scene, p_game_context)
    }

	field.reset_u8_input_field(p_input_field)
}
