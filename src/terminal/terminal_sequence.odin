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