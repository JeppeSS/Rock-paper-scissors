package terminal

import "core:fmt"


ESC :: "\x1b"
CSI :: "\x1b["


clear :: proc() {
    fmt.printf("%s2J", CSI)
}

hide_cursor :: proc() {
    fmt.printf("%s?25l", CSI)
}

move_cursor :: proc(x: int, y: int) {
    fmt.printf("%s%d;%dH", CSI, y, x)
}

write :: proc(text: string){
    fmt.printf("%s", text)
}

write_at :: proc(x: int, y: int, text: string) {
    fmt.printf("%s%d;%dH%s", CSI, y, x, text)
}

delete_at :: proc(x: int, y: int) {
    fmt.printf("%s%d;%dX", CSI, y, x)
}


// TODO[Jeppe]: Change this to chars instead.
draw_border :: proc(p_terminal: ^WinTerminal_t, top: string, bottom: string, left: string, right: string) {
    for i in 0..=p_terminal.width {
        write_at(cast(int)i, 0, top )
        write_at(cast(int)i, cast(int)p_terminal.height, bottom )
    }

    for j in 0..=p_terminal.height {
        write_at(0, cast(int)j, left )
        write_at(cast(int)p_terminal.width, cast(int)j, right )
    }
}

draw_box_at :: proc(x: int, y: int, width: u16, height: u16, top: string, bottom: string, left: string, right: string) {
    for i in cast(u16)x..=(cast(u16)x + width) {
        write_at(cast(int)i, y, top )
        write_at(cast(int)i, y + cast(int)height, bottom )
    }

     for j in cast(u16)y..=(cast(u16)y + height) {
        write_at(x, cast(int)j, left )
        write_at(x + cast(int)width, cast(int)j, right )
    }
}

draw_horizontal_line_at :: proc(x: int, y: int, width: u16, symbol: string) {
    for i in cast(u16)x..=(cast(u16)x + width) {
        write_at(cast(int)i, y, symbol )
    }
}