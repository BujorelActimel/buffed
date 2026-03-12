package main

import rl "vendor:raylib"
import "core:fmt"
import "core:mem"
import "core:os"
import "editor"
import "render"

run :: proc() {
    file_path := os.args[1] if len(os.args) > 1 else ""

    state, _ := editor.editor_init(file_path)
    defer editor.editor_destroy(&state)

    title: cstring = "Buffed"
    title_dirty: cstring = "Buffed *"
    prev_modified := false
    rl.SetWindowTitle(title)

    for !rl.WindowShouldClose() {
        editor.editor_handle_input(&state)
        rl.BeginDrawing()
        rl.ClearBackground(state.theme.bg)
        layout := render.layout_compute(rl.GetScreenWidth(), rl.GetScreenHeight(), &state.font, state.side_tree_open)
        render.render_top_bar(layout, &state.theme)
        render.render_side_tree(layout, &state.theme)
        if len(state.views) == 0 {
            render.render_splash(layout, &state.theme)
        } else {
            view := &state.views[state.active_view]
            render.render_gutter(layout, &state.theme)
            render.render_editor(&view.buf, &state.font, &state.theme, layout, view.cursor.head, view.scroll, state.config.tab_size)
        }
        render.render_status_bar(layout, &state.theme)
        rl.EndDrawing()
        modified := len(state.views) > 0 && state.views[state.active_view].buf.modified
        if prev_modified != modified {
            rl.SetWindowTitle(title_dirty if modified else title)
            prev_modified = modified
        }
    }
}

main :: proc() {
    tracker: mem.Tracking_Allocator
    mem.tracking_allocator_init(&tracker, context.allocator)
    defer mem.tracking_allocator_destroy(&tracker)
    context.allocator = mem.tracking_allocator(&tracker)

    run()

    for _, leak in tracker.allocation_map {
        fmt.printf("LEAK: %v bytes at %v\n", leak.size, leak.location)
    }
}
