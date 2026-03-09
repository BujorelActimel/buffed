package render

import rl "vendor:raylib"

SEPARATOR :: rl.Color{255, 255, 255, 40}

render_top_bar :: proc(layout: Layout, theme: ^Theme) {
    rl.DrawRectangleRec(layout.top_bar, theme.bg)
    // bottom border
    rl.DrawRectangle(0, i32(layout.top_bar.height) - 1, i32(layout.top_bar.width), 1, SEPARATOR)
}
