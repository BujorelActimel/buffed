package render

import rl "vendor:raylib"
import "../buffer"

render_gutter :: proc(layout: Layout, font: ^Font_Info, theme: ^Theme, buf: ^buffer.Buffer, cursor_head, scroll: int) {
    rl.DrawRectangleRec(layout.gutter, theme.bg_editor)

    cursor_line   := buffer_cursor_line(buf, cursor_head)
    line_count    := buffer.buffer_line_count(buf)
    visible_lines := int(layout.gutter.height / font.glyph_h) + 2
    last_line     := min(line_count, scroll + visible_lines)
    right_x       := layout.gutter.x + f32(layout.gutter_w) - font.glyph_w

    for line in scroll..<last_line {
        y     := layout.gutter.y + f32(line - scroll) * font.glyph_h
        color := theme.fg if line == cursor_line else theme.line_num

        // collect digits least-significant first
        digits: [8]rune
        d, n := 0, line + 1
        for n > 0 {
            digits[d] = rune('0' + n % 10)
            d += 1
            n /= 10
        }

        // draw right-aligned
        x := right_x
        for i in 0..<d {
            x -= font.glyph_w
            rl.DrawTextCodepoint(font.font, digits[i], {x, y}, font.glyph_h, color)
        }
    }

    // right border
    rl.DrawRectangle(layout.side_tree_w + layout.gutter_w - 1, i32(layout.gutter.y), 1, i32(layout.gutter.height), SEPARATOR)
}
