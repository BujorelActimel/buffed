package main

import rl "vendor:raylib"
import "core:fmt"
import "core:mem"
import "core:os"
import "editor"
import "render"

main :: proc() {
    tracker: mem.Tracking_Allocator
    mem.tracking_allocator_init(&tracker, context.allocator)
    defer mem.tracking_allocator_destroy(&tracker)
    context.allocator = mem.tracking_allocator(&tracker)

    // ----------------------------------------------------------------

    file_path := os.args[1] if len(os.args) > 1 else ""

    state, _ := editor.editor_init(file_path)
    defer editor.editor_destroy(&state)

    for !rl.WindowShouldClose() {
        rl.BeginDrawing()
        render.render_editor(&state.buff, &state.font, &state.theme)
        rl.EndDrawing()
    }

    // ----------------------------------------------------------------

    for _, leak in tracker.allocation_map {
        fmt.printf("LEAK: %v bytes at %v\n", leak.size, leak.location)
    }
}
