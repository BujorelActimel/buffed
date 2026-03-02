package render

import rl "vendor:raylib"
import "../buffer"

render_editor :: proc(buf: ^buffer.Buffer, font: ^Font_Info, theme: ^Theme) {
    screen_w := rl.GetScreenWidth()
    screen_h := rl.GetScreenHeight()

    rl.ClearBackground(theme.bg_editor)

    rl.BeginScissorMode(0, 0, screen_w, screen_h)
    defer rl.EndScissorMode()

    line_count    := buffer.buffer_line_count(buf)
    visible_lines := int(f32(screen_h) / font.glyph_h) + 2

    for i in 0..<min(line_count, visible_lines) {
        line := buffer.buffer_get_line(buf, i)
        y    := f32(i) * font.glyph_h

        x: f32 = 0
        for ch in line {
            rl.DrawTextCodepoint(font.font, ch, rl.Vector2{x, y}, font.glyph_h, theme.fg)
            x += font.glyph_w
        }
    }
}
