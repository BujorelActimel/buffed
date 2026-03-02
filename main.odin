package main

import rl "vendor:raylib"
import "core:fmt"
import "core:mem"
import "editor"

main :: proc() {
    tracker: mem.Tracking_Allocator
    mem.tracking_allocator_init(&tracker, context.allocator)
    defer mem.tracking_allocator_destroy(&tracker)
    context.allocator = mem.tracking_allocator(&tracker)

    // ----------------------------------------------------------------

    state, _ := editor.editor_init()
    defer editor.editor_destroy(&state)

    for !rl.WindowShouldClose() {
        rl.BeginDrawing()
        rl.ClearBackground(rl.BLACK)
        rl.EndDrawing()
    }

    // ----------------------------------------------------------------

    for _, leak in tracker.allocation_map {
        fmt.printf("LEAK: %v bytes at %v\n", leak.size, leak.location)
    }
}
