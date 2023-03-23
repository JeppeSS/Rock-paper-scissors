package main

import "core:fmt"

import "core:log"

import "hgl:terminal"
import "hgl:event"
import sm "hgl:scene"

import ctx "context"
import msc "game_scene"

main :: proc() {

	p_terminal, err := terminal.win_terminal_create()
	if(err != nil){
		fmt.println("[ERROR] Could not construct terminal: ", err)
		return
	}
	defer terminal.win_terminal_destroy(p_terminal)

	p_event_dispatcher := event.create_event_dispatcher()
	defer event.destroy_event_dispatcher(p_event_dispatcher)

	p_scene_manager := sm.create_scene_manager()

	// TODO[Jeppe]: Rethink this.
	main_menu_scene := msc.Main_Menu_Scene{}
	main_scene := sm.Scene_t {
		init   = msc.main_menu_scene_init,
		start  = msc.main_menu_scene_start,
		render = msc.main_menu_scene_render,
		update = msc.main_menu_scene_update,
		stop   = msc.main_menu_scene_stop,
		data   = &main_menu_scene,
	}
	sm.scene_manager_add_scene(p_scene_manager, "Main Menu", main_scene)

	classic_game_scene := msc.Classic_Game_Scene{}
	classic_scene := sm.Scene_t {
		init  = msc.classic_game_scene_init,
		start = msc.classic_game_scene_start,
		render = msc.classic_game_scene_render,
		update = msc.classic_game_scene_update,
		data  = &classic_game_scene,
	}

	sm.scene_manager_add_scene(p_scene_manager, "CLASSIC GAME", classic_scene)

	game_context := ctx.Game_Context_t{ 
		p_event_dispatcher = p_event_dispatcher,
		p_terminal         = p_terminal,
		p_scene_manager    = p_scene_manager,
	}

	defer sm.destroy_scene_manager(p_scene_manager, &game_context)

	register_event_handlers(p_event_dispatcher)


	sm.scene_manager_init_scenes(p_scene_manager, &game_context)
	sm.scene_manager_run_scene(p_scene_manager, &game_context, "Main Menu")


	terminal.hide_cursor()
	for terminal.win_terminal_running(p_terminal) {
		sm.scene_manager_render(p_scene_manager, &game_context)
		sm.scene_manager_update(p_scene_manager, &game_context)
	}
}


register_event_handlers :: proc(p_event_dispatcher: ^event.Event_Dispatcher_t) {
	event.register_handler(p_event_dispatcher, "QUIT_EVENT", quit_event_handler)
	event.register_handler(p_event_dispatcher, "CHANGE_SCENE_EVENT", change_scene_event_handler)
}

quit_event_handler :: proc(p_game_context: rawptr, p_event_data: rawptr){
	p_game_context := cast(^ctx.Game_Context_t)p_game_context
	terminal.stop(p_game_context.p_terminal)
}

change_scene_event_handler :: proc(p_game_context: rawptr, p_event_data: rawptr) {
	p_game_context := cast(^ctx.Game_Context_t)p_game_context
	p_new_scene_name := cast(^string)p_event_data
	terminal.clear()
	sm.scene_manager_run_scene(p_game_context.p_scene_manager, p_game_context, p_new_scene_name^)
}