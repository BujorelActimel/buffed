package main

import rl "vendor:raylib"
import "core:fmt"
import "core:mem"
import "core:os"
import "core:path/filepath"
import "core:math/rand"
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

    palette := [?]rl.Color{
        state.theme.keyword,  state.theme.function, state.theme.string_lit,
        state.theme.number,   state.theme.type_kw,  state.theme.constant,
        state.theme.attribute, state.theme.preproc,
    }
    i := rand.int_max(len(palette))
    j := (i + 1 + rand.int_max(len(palette) - 1)) % len(palette)
    logo_color1, logo_color2 := palette[i], palette[j]

    for !rl.WindowShouldClose() {
        editor.editor_handle_input(&state)

        layout := render.layout_compute(rl.GetScreenWidth(), rl.GetScreenHeight(), &state.font, state.side_tree_open)

        tabs := make([]render.Tab_Info, len(state.views), context.temp_allocator)
        for &view, i in state.views {
            name := filepath.base(view.buf.file_path)
            tabs[i] = {
                name     = name if name != "." else "",
                modified = view.buf.modified,
            }
        }

        // tab bar click — switch buffer on left click within top bar
        if rl.IsMouseButtonPressed(.LEFT) {
            mouse := rl.GetMousePosition()
            if mouse.y >= layout.top_bar.y && mouse.y < layout.top_bar.y + layout.top_bar.height {
                logo_w := f32(len("Buff-Ed")) * state.font.glyph_w + render.TAB_PAD_X * 2
                x := logo_w
                for idx in 0..<len(tabs) {
                    name  := tabs[idx].name if len(tabs[idx].name) > 0 else "untitled"
                    label_w := f32(len(name)) * state.font.glyph_w
                    if tabs[idx].modified do label_w += state.font.glyph_w * 2
                    tab_w := label_w + render.TAB_PAD_X * 2
                    if mouse.x >= x && mouse.x < x + tab_w {
                        state.active_view = idx
                        break
                    }
                    x += tab_w
                }
            }
        }

        rl.BeginDrawing()
        rl.ClearBackground(state.theme.bg)
        render.render_top_bar(layout, &state.font, &state.theme, tabs, state.active_view, logo_color1, logo_color2)
        render.render_side_tree(layout, &state.theme)
        if len(state.views) == 0 {
            render.render_splash(layout, &state.theme)
        } else {
            view := &state.views[state.active_view]
            render.render_gutter(layout, &state.font, &state.theme, &view.buf, view.cursor.head, view.scroll)
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
