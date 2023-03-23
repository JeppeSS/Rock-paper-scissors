package field

import inp "hgl:input"

U8_InputField_t :: struct {
	value:    u8,
	is_submitted: bool,
}


create_u8_input_field :: proc() -> U8_InputField_t {
	return U8_InputField_t{value = 0, is_submitted = false}
}

handle_key_event :: proc(key: inp.Key_e, is_down: bool, data: rawptr) {
	p_input_field := cast(^U8_InputField_t)data
	if is_down {
		#partial switch key {
			case .KEY_1:         p_input_field.value = 1
			case .KEY_2:         p_input_field.value = 2
			case .KEY_3:         p_input_field.value = 3
			case .KEY_4:         p_input_field.value = 4
			case .KEY_5:         p_input_field.value = 5
			case .KEY_BACKSPACE: p_input_field.value = 0
			case .KEY_ENTER:     p_input_field.is_submitted = (p_input_field.value > 0 && p_input_field.value < 6)
		}
	}
}

reset_u8_input_field :: proc(input_field: ^U8_InputField_t) {
	input_field.value        = 0
	input_field.is_submitted = false
}

