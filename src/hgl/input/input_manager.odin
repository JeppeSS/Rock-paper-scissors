package input


Key_Callback_t :: proc(key: Key_e, is_down: bool, data: rawptr)

Key_e :: enum {
	KEY_BACKSPACE,
	KEY_ENTER,
	KEY_ESC,
	KEY_1,
	KEY_2,
	KEY_3,
	KEY_4,
	KEY_5,
	KEY_A,
	KEY_B,
	KEY_D,
	KEY_S,
	KEY_W,
	KEY_UNKNOWN, // TODO[Jeppe]: Delete this when the rest of the keys are here.
}

InputManager_t :: struct {
	key_input: map[Key_e]bool,
	key_callback: Key_Callback_t,
	data: rawptr,
}



// TODO[Jeppe] Add key_callback
create_input_manager :: proc() -> ^InputManager_t {
	result := new(InputManager_t)
	result.key_input = make(map[Key_e]bool)
	return result
}

input_manager_register_key_callback :: proc(p_input_manager: ^InputManager_t, callback: Key_Callback_t, data: rawptr) {
	p_input_manager.key_callback = callback
	p_input_manager.data = data
}

input_manager_unregister_key_callback :: proc(p_input_manager: ^InputManager_t) {
	p_input_manager.key_callback = nil
	p_input_manager.data = nil
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
