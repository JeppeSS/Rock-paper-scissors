package main

import "core:fmt"
import win32 "core:sys/windows"


WinConsoleError_e :: enum {
	WIN_CONSOLE_SUCCESS,
	WIN_CONSOLE_COULD_NOT_GET_OUTPUT_HANDLE,
	WIN_CONSOLE_COULD_NOT_GET_CONSOLE_MODE,
	WIN_CONSOLE_COULD_NOT_SET_CONSOLE_MODE,
}


main :: proc() {

	if result := enable_virtual_terminal_sequences(); result != .WIN_CONSOLE_SUCCESS {
		fmt.println("[ERROR] Could not enable virtual sequences: ", result)
	}

}

enable_virtual_terminal_sequences :: proc() -> WinConsoleError_e {
	output_handle := win32.GetStdHandle( win32.STD_OUTPUT_HANDLE )
	if( output_handle == win32.INVALID_HANDLE_VALUE ) {
		return .WIN_CONSOLE_COULD_NOT_GET_OUTPUT_HANDLE
	}

	buffer_mode: u32 = 0
	if( !win32.GetConsoleMode( output_handle, &buffer_mode ) ) {
		return .WIN_CONSOLE_COULD_NOT_GET_CONSOLE_MODE
	}

	buffer_mode = buffer_mode | win32.ENABLE_VIRTUAL_TERMINAL_PROCESSING
	if( !win32.SetConsoleMode( output_handle, buffer_mode ) ){
		return .WIN_CONSOLE_COULD_NOT_SET_CONSOLE_MODE
	}

	return .WIN_CONSOLE_SUCCESS
}
