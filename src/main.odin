package main

import "core:fmt"
import win32 "core:sys/windows"

/*
	This enum represents the possible outcomes when using the Windows Console API. 
	It includes success and various error scenarios related to interactions with the console.
*/
WinConsoleError_e :: enum {
	WIN_CONSOLE_SUCCESS,             // This operation completed successfully.
	WIN_CONSOLE_OUTPUT_HANDLE_ERROR, // An error occured while fetching the STD_OUTPUT_HANDLE.
	WIN_CONSOLE_MODE_FETCH_ERROR,    // An error occured while fetching the console mode.
	WIN_CONSOLE_MODE_SET_ERROR,      // An error occured while setting or updating the console mode.
}


WinConsole_t :: struct {
	output_handle: win32.HANDLE,
} 


main :: proc() {
	console, err := create_win_console()
	if(err != .WIN_CONSOLE_SUCCESS){
		fmt.println("[ERROR] Could not construct console: ", err)
		return
	}
	defer free(console)
	



}

create_win_console :: proc() -> (^WinConsole_t, WinConsoleError_e) {
	if err := enable_virtual_terminal_sequences(); err != .WIN_CONSOLE_SUCCESS {
		return nil, err
	}

	output_handle, err := fetch_output_handle()
	if err != .WIN_CONSOLE_SUCCESS {
		return nil, err
	}
	
	result := new(WinConsole_t)
	result.output_handle = output_handle
	
	return result, .WIN_CONSOLE_SUCCESS
}

/*
	Enables Virtual Terminal Sequences in the windows console by fetching and updating
	the console mode of the 'STD_OUTPUT_HANDLE'.

	Virtual Terminal Sequences are a set of control sequences that enables advanced text formatting and styling,
	as well as other advanced features like mouse input, keyboard mapping and more.

	Return outcomes:
		WIN_CONSOLE_SUCCESS             - Operation completed successfully.
		WIN_CONSOLE_OUTPUT_HANDLE_ERROR - An error occured while fetching the 'STD_OUTPUT_HANDLE'.
		WIN_CONSOLE_MODE_FETCH_ERROR    - An error occured while fetching the console mode.
		WIN_CONSOLE_MODE_SET_ERROR      - An error occured while setting the 'ENABLE_VIRTUAL_TERMINAL_PROCESSING' flag.
*/
enable_virtual_terminal_sequences :: proc() -> WinConsoleError_e {
	output_handle, err := fetch_output_handle()
	if(err != .WIN_CONSOLE_SUCCESS){
		return err
	}

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
