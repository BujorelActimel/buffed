package render

import rl "vendor:raylib"

render_status_bar :: proc(layout: Layout, theme: ^Theme) {
    rl.DrawRectangleRec(layout.status_bar, theme.bg)
    // top border
    rl.DrawRectangle(0, i32(layout.status_bar.y), i32(layout.status_bar.width), 1, SEPARATOR)
}
