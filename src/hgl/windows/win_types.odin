package win_types

import win32 "core:sys/windows"


// TODO[Jeppe]: This is just for now, remove this when these are included in the Odin compiler.
foreign import kernel32 "system:Kernel32.lib"

@(default_calling_convention="stdcall")
foreign kernel32 {
	GetNumberOfConsoleInputEvents :: proc(hConsoleInput: win32.HANDLE, lpcNumberOfEvents: win32.LPDWORD) -> win32.BOOL ---
	ReadConsoleInputW :: proc(hConsoleInput: win32.HANDLE, lpBuffer: PINPUT_RECORD, nLength: win32.DWORD, lpNumberOfEventsRead: win32.LPDWORD) -> win32.BOOL ---
}



KEY_EVENT_RECORD :: struct {
	bKeyDown: win32.BOOL,
	wRepeatCount: win32.WORD,
	wVirtualKeyCode: win32.WORD,
	wVirtualScanCode: win32.WORD,
	uChar: struct #raw_union {
		UnicodeChar: win32.WCHAR,
		AsciiChar: win32.CHAR,
	},
	dwControlKeyState: win32.WORD,
}

MOUSE_EVENT_RECORD :: struct {
	dwMousePosition: win32.COORD,
	dwButtonState: win32.DWORD,
	dwControlKeyState: win32.DWORD,
	dwEventFlags: win32.DWORD,
}


WINDOW_BUFFER_SIZE_RECORD :: struct {
	dwSize: win32.COORD,
}

MENU_EVENT_RECORD :: struct {
	dwCommandId: win32.UINT,
}

PMENU_EVENT_RECORD :: ^MENU_EVENT_RECORD

FOCUS_EVENT_RECORD :: struct {
	bSetFocus: win32.BOOL,
}

INPUT_RECORD :: struct {
	EventType: win32.WORD,
	Event: struct #raw_union {
		KeyEvent: KEY_EVENT_RECORD,
		MouseEvent: MOUSE_EVENT_RECORD,
		WindowBufferSizeEvent: WINDOW_BUFFER_SIZE_RECORD,
		MenuEvent: MENU_EVENT_RECORD,
		FocusEvent: FOCUS_EVENT_RECORD,
	},
}

PINPUT_RECORD :: ^INPUT_RECORD

KEY_EVENT :: 0x0001
