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

    for !rl.WindowShouldClose() {
        editor.editor_handle_input(&state)
        rl.BeginDrawing()
        render.render_editor(&state.buff, &state.font, &state.theme, state.cursor.head, state.scroll)
        rl.EndDrawing()
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
