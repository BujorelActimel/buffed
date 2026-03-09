package render

import rl "vendor:raylib"

render_gutter :: proc(layout: Layout, theme: ^Theme) {
    rl.DrawRectangleRec(layout.gutter, theme.bg_editor)
    // right border
    rl.DrawRectangle(layout.side_tree_w + layout.gutter_w - 1, i32(layout.gutter.y), 1, i32(layout.gutter.height), SEPARATOR)
}
