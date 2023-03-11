package terminal

import "core:fmt"


ESC :: "\x1b"
CSI :: "\x1b["


terminal_clear :: proc() {
    fmt.printf("%s2J", CSI)
}

terminal_hide_cursor :: proc() {
    fmt.printf("%s?25l", CSI)
}

terminal_move_cursor :: proc(x: int, y: int) {
    fmt.printf("\033[%d;%dH",y, x)
}