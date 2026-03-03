package render

import rl "vendor:raylib"
import "../buffer"

render_editor :: proc(buf: ^buffer.Buffer, font: ^Font_Info, theme: ^Theme, cursor_head: int, scroll: int) {
    screen_w := rl.GetScreenWidth()
    screen_h := rl.GetScreenHeight()

    rl.ClearBackground(theme.bg_editor)

    rl.BeginScissorMode(0, 0, screen_w, screen_h)
    defer rl.EndScissorMode()

    line_count    := buffer.buffer_line_count(buf)
    visible_lines := int(f32(screen_h) / font.glyph_h) + 2
    first_line    := scroll
    last_line     := min(line_count, first_line + visible_lines)

    for i in first_line..<last_line {
        line := buffer.buffer_get_line(buf, i)
        y    := f32(i - scroll) * font.glyph_h

        x: f32 = 0
        for ch in line {
            rl.DrawTextCodepoint(font.font, ch, rl.Vector2{x, y}, font.glyph_h, theme.fg)
            x += font.glyph_w
        }
    }

    // block cursor
    cursor_line := buffer_cursor_line(buf, cursor_head)
    cursor_col  := cursor_head - buffer.buffer_line_start(buf, cursor_line)
    cursor_x    := f32(cursor_col) * font.glyph_w
    cursor_y    := f32(cursor_line - scroll) * font.glyph_h

    rl.DrawRectangleV(
        rl.Vector2{cursor_x, cursor_y},
        rl.Vector2{font.glyph_w, font.glyph_h},
        theme.cursor,
    )
    if cursor_head < len(buf.data) {
        ch := rune(buf.data[cursor_head])
        if ch != '\n' {
            rl.DrawTextCodepoint(font.font, ch, rl.Vector2{cursor_x, cursor_y}, font.glyph_h, theme.bg_editor)
        }
    }
}

// binary search - mirrors cursor_line from the cursor package
// kept here to avoid a circular import (render → cursor → buffer → render)
buffer_cursor_line :: proc(buf: ^buffer.Buffer, pos: int) -> int {
    lo, hi := 0, len(buf.line_ends) - 1
    for lo < hi {
        mid := lo + (hi - lo) / 2
        if buf.line_ends[mid] < pos {
            lo = mid + 1
        } else {
            hi = mid
        }
    }
    return lo
}
