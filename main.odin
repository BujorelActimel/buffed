package main

import "core:fmt"
import "core:mem"
import "config"

main :: proc() {
    tracker: mem.Tracking_Allocator
    mem.tracking_allocator_init(&tracker, context.allocator)
    defer mem.tracking_allocator_destroy(&tracker)
    context.allocator = mem.tracking_allocator(&tracker)

    // ----------------------------------------------------------------

    fmt.println("Buff-Ed biatch")
    
    configuration, ok := config.config_load()
    if !ok {
        fmt.println("Using default config")
    }

    // ----------------------------------------------------------------

    for _, leak in tracker.allocation_map {
        fmt.printf("LEAK: %v bytes at %v\n", leak.size, leak.location)
    }
}
