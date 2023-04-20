package windows

import win "core:sys/windows"


foreign import kernel32 "system:Kernel32.lib"

@(default_calling_convention="stdcall")
foreign kernel32 {
	GetNumberOfConsoleInputEvents :: proc(hConsoleInput: win.HANDLE, lpcNumberOfEvents: win.LPDWORD) -> win.BOOL ---
	ReadConsoleInputW :: proc(hConsoleInput: win.HANDLE, lpBuffer: PINPUT_RECORD, nLength: win.DWORD, lpNumberOfEventsRead: win.LPDWORD) -> win.BOOL ---
}



KEY_EVENT_RECORD :: struct {
	bKeyDown: win.BOOL,
	wRepeatCount: win.WORD,
	wVirtualKeyCode: win.WORD,
	wVirtualScanCode: win.WORD,
	uChar: struct #raw_union {
		UnicodeChar: win.WCHAR,
		AsciiChar: win.CHAR,
	},
	dwControlKeyState: win.WORD,
}

MOUSE_EVENT_RECORD :: struct {
	dwMousePosition: win.COORD,
	dwButtonState: win.DWORD,
	dwControlKeyState: win.DWORD,
	dwEventFlags: win.DWORD,
}


WINDOW_BUFFER_SIZE_RECORD :: struct {
	dwSize: win.COORD,
}

MENU_EVENT_RECORD :: struct {
	dwCommandId: win.UINT,
}

PMENU_EVENT_RECORD :: ^MENU_EVENT_RECORD

FOCUS_EVENT_RECORD :: struct {
	bSetFocus: win.BOOL,
}

INPUT_RECORD :: struct {
	EventType: win.WORD,
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
