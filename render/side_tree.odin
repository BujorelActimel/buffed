package render

import rl "vendor:raylib"

render_side_tree :: proc(layout: Layout, theme: ^Theme) {
    if layout.side_tree_w == 0 do return
    rl.DrawRectangleRec(layout.side_tree, theme.bg)
    // right border
    rl.DrawRectangle(layout.side_tree_w - 1, i32(layout.side_tree.y), 1, i32(layout.side_tree.height), SEPARATOR)
}
