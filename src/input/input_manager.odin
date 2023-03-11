package input


Key_e :: enum {
	KEY_ESC,
	KEY_A,
	KEY_B,
	KEY_UNKNOWN, // TODO[Jeppe]: Delete this when the rest of the keys are here.
}

InputManager_t :: struct {
	key_input: map[Key_e]bool,
	key_callback: proc(key: Key_e, is_down: bool),
}



// TODO[Jeppe] Add key_callback
create_input_manager :: proc() -> ^InputManager_t {
	result := new(InputManager_t)
	result.key_input = make(map[Key_e]bool)
	return result
}

destroy_input_manager :: proc(p_input_manager: ^InputManager_t) {
	delete(p_input_manager.key_input)
	free(p_input_manager)
}


toggle_key :: proc(p_input_manager: ^InputManager_t, key: Key_e, is_down: bool){
	p_input_manager.key_input[key] = is_down
}

is_key_down :: proc(p_input_manager: ^InputManager_t, key: Key_e) -> bool {
	return p_input_manager.key_input[key]
}
