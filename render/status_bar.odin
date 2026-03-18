package render

import "core:path/filepath"
import rl "vendor:raylib"
import "../buffer"

render_status_bar :: proc(layout: Layout, font: ^Font_Info, theme: ^Theme, buf: ^buffer.Buffer, cursor_head: int, branch: string) {
    rl.DrawRectangleRec(layout.status_bar, theme.bg)
    // top border
    rl.DrawRectangle(0, i32(layout.status_bar.y), i32(layout.status_bar.width), 1, SEPARATOR)

    if buf == nil do return

    text_y := layout.status_bar.y + (layout.status_bar.height - font.glyph_h) / 2
    x      := layout.status_bar.x + font.glyph_w * 2

    // branch
    if branch != "" {
        for ch in branch {
            rl.DrawTextCodepoint(font.font, ch, {x, text_y}, font.glyph_h, theme.operator)
            x += font.glyph_w
        }
        x += font.glyph_w * 3
    }

    // filename
    name := filepath.base(buf.file_path) if buf.file_path != "" else "untitled"
    for ch in name {
        rl.DrawTextCodepoint(font.font, ch, {x, text_y}, font.glyph_h, theme.fg)
        x += font.glyph_w
    }

    // [*] if modified
    if buf.modified {
        for ch in " [*]" {
            rl.DrawTextCodepoint(font.font, ch, {x, text_y}, font.glyph_h, theme.warning)
            x += font.glyph_w
        }
    }

    // line:col right-aligned
    line     := buffer_cursor_line(buf, cursor_head)
    col      := cursor_head - buffer.buffer_line_start(buf, line)
    line_col := string(rl.TextFormat("%d:%d", line + 1, col + 1))
    rx := layout.status_bar.x + layout.status_bar.width - f32(len(line_col)) * font.glyph_w - font.glyph_w * 2
    for ch in line_col {
        rl.DrawTextCodepoint(font.font, ch, {rx, text_y}, font.glyph_h, theme.fg)
        rx += font.glyph_w
    }
}
