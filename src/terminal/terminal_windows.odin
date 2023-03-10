package terminal

import "core:fmt"
import win32 "core:sys/windows"

import inp "../input"
import win "../windows"


/*
	This enum represents the possible outcomes when using the Windows Console API. 
	It includes success and various error scenarios related to interactions with the terminal.
*/
WinTerminalError_e :: enum {
	WIN_CONSOLE_OUTPUT_HANDLE_ERROR,       // An error occured while fetching the STD_OUTPUT_HANDLE.
	WIN_CONSOLE_INPUT_HANDLE_ERROR,        // An error occured while fetching the STD_INPUT_HANDLE.
	WIN_CONSOLE_MODE_FETCH_ERROR,          // An error occured while fetching the console mode.
	WIN_CONSOLE_MODE_SET_ERROR,      	   // An error occured while setting or updating the console mode.
	WIN_CONSOLE_SCREEN_BUFFER_FETCH_ERROR, // An error occured while fetching the console screen buffer.
	WIN_CONSOLE_READ_INPUT_ERROR,          // An error occured while fetching input records from the console.
}


WinTerminal_t :: struct {
	output_handle:   win32.HANDLE,
	input_handle:    win32.HANDLE,
	width:           i16,
	height:          i16,
	is_running:      bool,
	p_input_manager: ^inp.InputManager_t,
} 


win_terminal_create :: proc() -> (p_terminal: ^WinTerminal_t, err: WinTerminalError_e) {
	// Fetch handles	
	output_handle := fetch_output_handle() or_return
	input_handle  := fetch_input_handle() or_return

	// Enable settings on handles.
	enable_virtual_terminal_sequences(output_handle) or_return
	enable_input_events(input_handle) or_return

	// Fetch terminal dimensions
	width, height := fetch_terminal_size(output_handle) or_return
	
	result                 := new(WinTerminal_t)
	result.output_handle   = output_handle
	result.input_handle    = input_handle
	result.width           = width
	result.height          = height
	result.is_running      = true
	result.p_input_manager = inp.create_input_manager()
	
	prepare_terminal();
	
	return result, nil
}

prepare_terminal :: proc() {
	fmt.printf("%s?1049h", CSI) // Alternate buffer begin
	clear()
	move_cursor(0, 1)
}

win_terminal_stop :: proc(p_terminal: ^WinTerminal_t) {
	p_terminal.is_running = false
}

// TODO[Jeppe]: Reconsider name
reset_terminal :: proc() {
	fmt.printf("%s?1049l", CSI) // Alternate buffer end
}

win_terminal_running :: proc(p_terminal: ^WinTerminal_t) -> bool {
	if(p_terminal.is_running){
		if(listen_input_events(p_terminal.input_handle, p_terminal.p_input_manager) != nil){
			return false;
		}

	}
	return p_terminal.is_running
}


win_terminal_destroy :: proc(p_terminal: ^WinTerminal_t) {
	reset_terminal()

	inp.destroy_input_manager(p_terminal.p_input_manager)
	win32.CloseHandle(p_terminal.output_handle)
	win32.CloseHandle(p_terminal.input_handle)
	free(p_terminal)
}


listen_input_events :: proc(input_handle: win32.HANDLE, p_input_manager: ^inp.InputManager_t) -> WinTerminalError_e {
	events_read: u32 = 0
	input_records: [32]win.INPUT_RECORD
	if(!win.ReadConsoleInputW(input_handle, &input_records[0], 32, &events_read)){
		return .WIN_CONSOLE_READ_INPUT_ERROR
	}

	for input_record in input_records {
		switch(input_record.EventType){
			case win.KEY_EVENT:
				key_event := input_record.Event.KeyEvent
				key := from_virtual_key_code_to_key(key_event.wVirtualKeyCode)
				is_down := cast(bool)key_event.bKeyDown
				inp.toggle_key(p_input_manager, key, is_down)
				if p_input_manager.key_callback != nil {
					p_input_manager.key_callback(key, is_down)
				}
		}
	}
	
	return nil
}

from_virtual_key_code_to_key :: proc(key_code: win32.WORD) -> inp.Key_e {
	win_key_map := map[win32.WORD]inp.Key_e {
		0x1B = .KEY_ESC,
		0x41 = .KEY_A,
		0x42 = .KEY_B,
		0x44 = .KEY_D,
		0x53 = .KEY_S,
		0x57 = .KEY_W,
	}
	key := win_key_map[key_code] or_else .KEY_UNKNOWN
	return key
}



/*
	Retrieves the size of a Windows terminal given its output handle.

	Parameters:
		- output_handle: A handle to the terminal output for which the size is to be retrieved.

	Returns:
		- width: An i16 value representing the width of the terminal, in characters.
		- height: An i16 value representing the height of the terminal, in characters.
		- error: A WinTerminalError_e value indicating the outcome of the procedure.
			- 'WIN_CONSOLE_SCREEN_BUFFER_FETCH_ERROR', indicating an error while retrieving the console screen buffer information.
			- 'nil' if the procedure completed successfully.
*/
fetch_terminal_size :: proc(output_handle: win32.HANDLE) -> (i16, i16, WinTerminalError_e) {
	terminal_buffer_info: win32.CONSOLE_SCREEN_BUFFER_INFO
	if( !win32.GetConsoleScreenBufferInfo(output_handle, &terminal_buffer_info) ) {
		return 0, 0, .WIN_CONSOLE_SCREEN_BUFFER_FETCH_ERROR
	}

	width  := terminal_buffer_info.dwSize.X
	height := terminal_buffer_info.dwSize.Y 

	return width, height, nil
}

/*
	Enables Virtual Terminal Sequences in the windows terminal by updating the terminal
	mode of the output handle.

	Virtual Terminal Sequences are a set of control sequences that enables advanced text formatting and styling,
	as well as other advanced features like mouse input, keyboard mapping and more.

	Error outcomes:
		WIN_CONSOLE_MODE_FETCH_ERROR    - An error occured while fetching the terminal mode.
		WIN_CONSOLE_MODE_SET_ERROR      - An error occured while setting the 'ENABLE_VIRTUAL_TERMINAL_PROCESSING' flag.
*/
enable_virtual_terminal_sequences :: proc(output_handle: win32.HANDLE) -> WinTerminalError_e {
	buffer_mode: u32 = 0
	if( !win32.GetConsoleMode( output_handle, &buffer_mode ) ) {
		return .WIN_CONSOLE_MODE_FETCH_ERROR
	}

	buffer_mode = buffer_mode | win32.ENABLE_VIRTUAL_TERMINAL_PROCESSING
	if( !win32.SetConsoleMode( output_handle, buffer_mode ) ){
		return .WIN_CONSOLE_MODE_SET_ERROR
	}
	
	return nil
}

/*
	Enables input events in the windows terminal by updating terminal mode
	for the input handler.

	By allowing input events, it gives the possibility to fetch and catch keyboard,
	mouse and terminal size adjustment events and respond to them accordingly

	Error outcomes:
		WIN_CONSOLE_MODE_SET_ERROR     - An error occured while setting terminal flags.
*/
enable_input_events :: proc(input_handle: win32.HANDLE) -> WinTerminalError_e {
	buffer_mode: u32 = win32.ENABLE_WINDOW_INPUT | win32.ENABLE_MOUSE_INPUT
	if !win32.SetConsoleMode( input_handle, buffer_mode ) {
		return .WIN_CONSOLE_MODE_SET_ERROR
	}
	
	return nil
}
/*
	Fetches the 'STD_OUTPUT_HANDLE' and returns it if succesfully. 

	Error outcomes:
		WIN_CONSOLE_OUTPUT_HANDLE_ERROR - An error occured while fetching the 'STD_OUTPUT_HANDLE'.
*/
fetch_output_handle :: proc() -> (win32.HANDLE, WinTerminalError_e) {
	output_handle := win32.GetStdHandle( win32.STD_OUTPUT_HANDLE )
	if( output_handle == win32.INVALID_HANDLE_VALUE ) {
		return win32.INVALID_HANDLE_VALUE, .WIN_CONSOLE_OUTPUT_HANDLE_ERROR
	}

	return output_handle, nil
}

/*
	Fetches the 'STD_INPUT_HANDLE' and returns it if succesfully. 

	Error outcomes:
		WIN_CONSOLE_INPUT_HANDLE_ERROR  - An error occured while fetching the 'STD_INPUT_HANDLE'.
*/
fetch_input_handle :: proc() -> (win32.HANDLE, WinTerminalError_e) {
	input_handle := win32.GetStdHandle( win32.STD_INPUT_HANDLE )
	if( input_handle == win32.INVALID_HANDLE_VALUE ) {
		return win32.INVALID_HANDLE_VALUE, .WIN_CONSOLE_INPUT_HANDLE_ERROR
	}

	return input_handle, nil
}
