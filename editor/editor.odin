package editor

import rl "vendor:raylib"
import "../config"
import "../render"
import "../buffer"
import "../cursor"

Buffer_View :: struct {
    buf:    buffer.Buffer,
    cursor: cursor.Selection,
    scroll: int,
}

Editor_State :: struct {
    config:          config.Config,
    theme:           render.Theme,
    font:            render.Font_Info,
    views:           [dynamic]Buffer_View,
    active_view:     int,
    keymap:          Keymap,
    side_tree_open:  bool,
}

editor_init :: proc(file_path: string) -> (Editor_State, bool) {
    state: Editor_State

    state.config, _ = config.config_load()
    state.theme,  _ = render.theme_load(state.config)

    rl.SetConfigFlags({.WINDOW_RESIZABLE})
    rl.InitWindow(0, 0, "Buffed")
    rl.SetExitKey(.KEY_NULL)
    rl.SetTargetFPS(60)

    state.font           = render.font_load(state.config)
    state.keymap         = keymap_default()
    state.side_tree_open = false

    if file_path != "" {
        editor_open(&state, file_path)
    }

    return state, true
}

editor_destroy :: proc(state: ^Editor_State) {
    config.config_destroy(&state.config)
    for &view in state.views {
        buffer.buffer_destroy(&view.buf)
    }
    delete(state.views)
    rl.UnloadFont(state.font.font)
    delete(state.keymap)
    rl.CloseWindow()
}

editor_open :: proc(state: ^Editor_State, path: string) {
    buff, ok := buffer.buffer_load_file(path)
    if !ok do return
    append(&state.views, Buffer_View{buf = buff})
    state.active_view = len(state.views) - 1
}

editor_close :: proc(state: ^Editor_State) {
    if len(state.views) == 0 do return
    buffer.buffer_destroy(&state.views[state.active_view].buf)
    ordered_remove(&state.views, state.active_view)
    if state.active_view > 0 do state.active_view -= 1
}

editor_next_buffer :: proc(state: ^Editor_State) {
    if len(state.views) == 0 do return
    state.active_view = (state.active_view + 1) % len(state.views)
}

editor_prev_buffer :: proc(state: ^Editor_State) {
    if len(state.views) == 0 do return
    state.active_view = (state.active_view - 1 + len(state.views)) % len(state.views)
}
