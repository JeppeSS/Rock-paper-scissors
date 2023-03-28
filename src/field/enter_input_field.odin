package field

import inp "hgl:input"


Enter_InputField_t :: struct {
	is_submitted: bool,
}


create_enter_input_field :: proc() -> Enter_InputField_t {
	return Enter_InputField_t{is_submitted = false}
}

handle_enter_field_key_event :: proc(key: inp.Key_e, is_down: bool, data: rawptr) {
	p_input_field := cast(^Enter_InputField_t)data
	if is_down && key == .KEY_ENTER {
        p_input_field.is_submitted = true
	}
}

reset_enter_input_field :: proc(input_field: ^Enter_InputField_t) {
	input_field.is_submitted = false
}