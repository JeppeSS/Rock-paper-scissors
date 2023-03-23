package game_context

import "hgl:terminal"
import "hgl:event"
import sm "hgl:scene"


Game_Context_t :: struct {
	p_event_dispatcher: ^event.Event_Dispatcher_t,
	p_terminal: ^terminal.WinTerminal_t,
	p_scene_manager: ^sm.Scene_Manager_t,
}