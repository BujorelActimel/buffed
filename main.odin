package main

import rl "vendor:raylib"
import "core:fmt"
import "core:mem"
import "config"
import "render"

main :: proc() {
    tracker: mem.Tracking_Allocator
    mem.tracking_allocator_init(&tracker, context.allocator)
    defer mem.tracking_allocator_destroy(&tracker)
    context.allocator = mem.tracking_allocator(&tracker)

    // ----------------------------------------------------------------
    
    configuration, ok := config.config_load()
    if !ok {
        fmt.println("Using default config")
    }

    rl.InitWindow(800, 600, "Buffed")
    defer rl.CloseWindow()

    font := render.font_load(configuration)

    // ----------------------------------------------------------------

    for _, leak in tracker.allocation_map {
        fmt.printf("LEAK: %v bytes at %v\n", leak.size, leak.location)
    }
}
