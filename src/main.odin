package main

import "core:fmt"
import "core:time" // TODO[Jeppe]: This is just for test
import win32 "core:sys/windows"


/*
	This enum represents the possible outcomes when using the Windows Console API. 
	It includes success and various error scenarios related to interactions with the console.
*/
WinConsoleError_e :: enum {
	WIN_CONSOLE_OUTPUT_HANDLE_ERROR,       // An error occured while fetching the STD_OUTPUT_HANDLE.
	WIN_CONSOLE_INPUT_HANDLE_ERROR,        // An error occured while fetching the STD_INPUT_HANDLE.
	WIN_CONSOLE_MODE_FETCH_ERROR,          // An error occured while fetching the console mode.
	WIN_CONSOLE_MODE_SET_ERROR,      	   // An error occured while setting or updating the console mode.
	WIN_CONSOLE_SCREEN_BUFFER_FETCH_ERROR, // An error occured while fetching the console screen buffer.
}


WinConsole_t :: struct {
	output_handle: win32.HANDLE,
	input_handle:  win32.HANDLE,
	width:         i16,
	height:        i16,
} 


ESC :: "\x1b"
CSI :: "\x1b["


main :: proc() {
	console, err := create_win_console()
	if(err != nil){
		fmt.println("[ERROR] Could not construct console: ", err)
		return
	}
	defer destroy_win_console(console)

	fmt.printf("%d:%d", console.width, console.height)
	

	/*
	fmt.printf("%s?1049h", CSI) // Alternate buffer begin
	fmt.printf("%s2J", CSI)     // Clear console

	fmt.printf("Hello World!")


	time.sleep(5000 * time.Millisecond)
	
	fmt.printf("%s?1049l", CSI) // Alternate buffer end
	*/
	


}


create_win_console :: proc() -> (p_console: ^WinConsole_t, err: WinConsoleError_e) {
	// Fetch handles	
	output_handle := fetch_output_handle() or_return
	input_handle  := fetch_input_handle() or_return

	// Enable settings on handles.
	enable_virtual_terminal_sequences(output_handle) or_return
	enable_input_events(input_handle) or_return

	// Fetch console dimensions
	width, height := fetch_console_size(output_handle) or_return
	
	result               := new(WinConsole_t)
	result.output_handle = output_handle
	result.input_handle  = input_handle
	result.width         = width
	result.height        = height

	return result, nil
}


destroy_win_console :: proc(console: ^WinConsole_t) {
	win32.CloseHandle(console.output_handle)
	win32.CloseHandle(console.input_handle)
	free(console)
}


/*
	Retrieves the size of a Windows console given its output handle.

	Parameters:
		- output_handle: A handle to the console output for which the size is to be retrieved.

	Returns:
		- width: An i16 value representing the width of the console, in characters.
		- height: An i16 value representing the height of the console, in characters.
		- error: A WinConsoleError_e value indicating the outcome of the procedure.
			- 'WIN_CONSOLE_SCREEN_BUFFER_FETCH_ERROR', indicating an error while retrieving the console screen buffer information.
			- 'nil' if the procedure completed successfully.
*/
fetch_console_size :: proc(output_handle: win32.HANDLE) -> (i16, i16, WinConsoleError_e) {
	console_buffer_info: win32.CONSOLE_SCREEN_BUFFER_INFO
	if( !win32.GetConsoleScreenBufferInfo(output_handle, &console_buffer_info) ) {
		return 0, 0, .WIN_CONSOLE_SCREEN_BUFFER_FETCH_ERROR
	}

	width  := console_buffer_info.dwSize.X
	height := console_buffer_info.dwSize.Y 

	return width, height, nil
}

/*
	Enables Virtual Terminal Sequences in the windows console by updating the console
	mode of the output handle.

	Virtual Terminal Sequences are a set of control sequences that enables advanced text formatting and styling,
	as well as other advanced features like mouse input, keyboard mapping and more.

	Error outcomes:
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
	
	return nil
}

/*
	Enables input events in the windows console by updating console mode
	for the input handler.

	By allowing input events, it gives the possibility to fetch and catch keyboard,
	mouse and console size adjustment events and respond to them accordingly

	Error outcomes:
		WIN_CONSOLE_MODE_SET_ERROR     - An error occured while setting console flags.
*/
enable_input_events :: proc(input_handle: win32.HANDLE) -> WinConsoleError_e {
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
fetch_output_handle :: proc() -> (win32.HANDLE, WinConsoleError_e) {
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
fetch_input_handle :: proc() -> (win32.HANDLE, WinConsoleError_e) {
	input_handle := win32.GetStdHandle( win32.STD_INPUT_HANDLE )
	if( input_handle == win32.INVALID_HANDLE_VALUE ) {
		return win32.INVALID_HANDLE_VALUE, .WIN_CONSOLE_INPUT_HANDLE_ERROR
	}

	return input_handle, nil
}
