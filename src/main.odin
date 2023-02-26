package main

import "core:fmt"
import "core:time" // TODO[Jeppe]: This is just for test
import win32 "core:sys/windows"

/*
	This enum represents the possible outcomes when using the Windows Console API. 
	It includes success and various error scenarios related to interactions with the console.
*/
WinConsoleError_e :: enum {
	WIN_CONSOLE_SUCCESS,             // This operation completed successfully.
	WIN_CONSOLE_OUTPUT_HANDLE_ERROR, // An error occured while fetching the STD_OUTPUT_HANDLE.
	WIN_CONSOLE_INPUT_HANDLE_ERROR,  // An error occured while fetching the STD_INPUT_HANDLE.
	WIN_CONSOLE_MODE_FETCH_ERROR,    // An error occured while fetching the console mode.
	WIN_CONSOLE_MODE_SET_ERROR,      // An error occured while setting or updating the console mode.
}


WinConsole_t :: struct {
	output_handle: win32.HANDLE,
	input_handle:  win32.HANDLE,
} 


ESC :: "\x1b"
CSI :: "\x1b["


main :: proc() {
	console, err := create_win_console()
	if(err != .WIN_CONSOLE_SUCCESS){
		fmt.println("[ERROR] Could not construct console: ", err)
		return
	}
	defer destroy_win_console(console)


	fmt.printf("%s?1049h", CSI) // Alternate buffer begin
	fmt.printf("%s2J", CSI)     // Clear console

	fmt.printf("Hello World!")


	time.sleep(5000 * time.Millisecond)
	
	fmt.printf("%s?1049l", CSI) // Alternate buffer end
	


}


create_win_console :: proc() -> (^WinConsole_t, WinConsoleError_e) {
	output_handle, err1 := fetch_output_handle()
	if err1 != .WIN_CONSOLE_SUCCESS {
		return nil, err1
	}
							

	if err := enable_virtual_terminal_sequences(output_handle); err != .WIN_CONSOLE_SUCCESS {
		return nil, err
	}


	input_handle, err2 := fetch_input_handle()
	if err2 != .WIN_CONSOLE_SUCCESS {
		return nil, err2
	}
	

	if err := enable_input_events(input_handle); err != .WIN_CONSOLE_SUCCESS {
		return nil, err
	}


	
	result := new(WinConsole_t)
	result.output_handle = output_handle
	result.input_handle  = input_handle
	
	return result, .WIN_CONSOLE_SUCCESS
}


destroy_win_console :: proc(console: ^WinConsole_t) {
	win32.CloseHandle(console.output_handle)
	win32.CloseHandle(console.input_handle)
	free(console)
}

/*
	Enables Virtual Terminal Sequences in the windows console by updating the console
	mode of the output handle.

	Virtual Terminal Sequences are a set of control sequences that enables advanced text formatting and styling,
	as well as other advanced features like mouse input, keyboard mapping and more.

	Return outcomes:
		WIN_CONSOLE_SUCCESS             - Operation completed successfully.
		WIN_CONSOLE_MODE_FETCH_ERROR    - An error occured while fetching the console mode.
		WIN_CONSOLE_MODE_SET_ERROR      - An error occured while setting the 'ENABLE_VIRTUAL_TERMINAL_PROCESSING' flag.
*/
enable_virtual_terminal_sequences :: proc(output_handle: win32.HANDLE) -> WinConsoleError_e {
	buffer_mode: u32 = 0
	if( !win32.GetConsoleMode( output_handle, &buffer_mode ) ) {
		return .WIN_CONSOLE_MODE_FETCH_ERROR
	}

	buffer_mode = buffer_mode | win32.ENABLE_VIRTUAL_TERMINAL_PROCESSING
	if( !win32.SetConsoleMode( output_handle, buffer_mode ) ){
		return .WIN_CONSOLE_MODE_SET_ERROR
	}
	
	return .WIN_CONSOLE_SUCCESS
}

/*
	Enables input events in the windows console by updating console mode
	for the input handler.

	By allowing input events, it gives the possibility to fetch and catch keyboard,
	mouse and console size adjustment events and respond to them accordingly

	Return outcomes:
		WIN_CONSOLE_SUCCESS            - Operation completed successfully.
		WIN_CONSOLE_MODE_SET_ERROR     - An error occured while setting console flags.
*/
enable_input_events :: proc(input_handle: win32.HANDLE) -> WinConsoleError_e {
	buffer_mode: u32 = win32.ENABLE_WINDOW_INPUT | win32.ENABLE_MOUSE_INPUT
	if !win32.SetConsoleMode( input_handle, buffer_mode ) {
		return .WIN_CONSOLE_MODE_SET_ERROR
	}
	
	return .WIN_CONSOLE_SUCCESS
}

/*
	Fetches the 'STD_OUTPUT_HANDLE' and returns it if succesfully. 

	Return outcomes:
		WIN_CONSOLE_SUCCESS             - Operation completed successfully.
		WIN_CONSOLE_OUTPUT_HANDLE_ERROR - An error occured while fetching the 'STD_OUTPUT_HANDLE'.
*/
fetch_output_handle :: proc() -> (win32.HANDLE, WinConsoleError_e) {
	output_handle := win32.GetStdHandle( win32.STD_OUTPUT_HANDLE )
	if( output_handle == win32.INVALID_HANDLE_VALUE ) {
		return win32.INVALID_HANDLE_VALUE, .WIN_CONSOLE_OUTPUT_HANDLE_ERROR
	}

	return output_handle, .WIN_CONSOLE_SUCCESS
}

/*
	Fetches the 'STD_INPUT_HANDLE' and returns it if succesfully. 

	Return outcomes:
		WIN_CONSOLE_SUCCESS             - Operation completed successfully.
		WIN_CONSOLE_INPUT_HANDLE_ERROR  - An error occured while fetching the 'STD_INPUT_HANDLE'.
*/
fetch_input_handle :: proc() -> (win32.HANDLE, WinConsoleError_e) {
	input_handle := win32.GetStdHandle( win32.STD_INPUT_HANDLE )
	if( input_handle == win32.INVALID_HANDLE_VALUE ) {
		return win32.INVALID_HANDLE_VALUE, .WIN_CONSOLE_INPUT_HANDLE_ERROR
	}

	return input_handle, .WIN_CONSOLE_SUCCESS
}
