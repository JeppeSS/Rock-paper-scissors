package event

// TODO[Jeppe]: Figure something out about the game_context, not sure this is the best way
Event_Handler_t :: proc(p_game_context: rawptr = nil, p_event_data: rawptr = nil)

// TODO[Jeppe]: Would it be possible to use some generic type as key to the handlers map?
Event_Dispatcher_t :: struct {
	handlers: map[string]Event_Handler_t,
}

create_event_dispatcher :: proc() -> ^Event_Dispatcher_t {
    p_dispatcher         := new(Event_Dispatcher_t)
    p_dispatcher.handlers = make(map[string]Event_Handler_t)
    return p_dispatcher
}


register_handler :: proc "contextless" (p_event_dispatcher: ^Event_Dispatcher_t, event_type: string, event_handler: Event_Handler_t) {
    p_event_dispatcher.handlers[event_type] = event_handler
}

unregister_handler :: proc (p_event_dispatcher: ^Event_Dispatcher_t, event_type: string) {
    ok := event_type in p_event_dispatcher.handlers
    if ok {
        delete_key(&p_event_dispatcher.handlers, event_type)
    }
}

dispatch_event :: proc(p_event_dispatcher: ^Event_Dispatcher_t, event_type: string, p_event_data: rawptr = nil, p_game_context: rawptr = nil) {
    event_handler, ok := p_event_dispatcher.handlers[event_type]
    if ok {
        event_handler(p_game_context, p_event_data)
    }

}

destroy_event_dispatcher :: proc(p_event_dispatcher: ^Event_Dispatcher_t) {
    delete(p_event_dispatcher.handlers)
    free(p_event_dispatcher)
}