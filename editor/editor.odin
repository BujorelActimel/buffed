package editor

import rl "vendor:raylib"
import "../config"
import "../render"
import "../buffer"
import "../cursor"

Editor_State :: struct {
    config:          config.Config,
    theme:           render.Theme,
    font:            render.Font_Info,
    buff:            buffer.Buffer,
    cursor:          cursor.Selection,
    keymap:          Keymap,
    scroll:          int,
    side_tree_open:  bool,
}

editor_init :: proc(file_path: string) -> (Editor_State, bool) {
    state: Editor_State

    state.config, _ = config.config_load()
    state.theme,  _ = render.theme_load(state.config)

    rl.SetConfigFlags({.WINDOW_RESIZABLE})
    rl.InitWindow(0, 0, "Buffed")
    rl.SetTargetFPS(60)

    state.font           = render.font_load(state.config)
    state.keymap         = keymap_default()
    state.side_tree_open = true

    if file_path != "" {
        state.buff, _ = buffer.buffer_load_file(file_path)
    }

    return state, true
}

editor_destroy :: proc(state: ^Editor_State) {
    config.config_destroy(&state.config)
    buffer.buffer_destroy(&state.buff)
    rl.UnloadFont(state.font.font)
    delete(state.keymap)
    rl.CloseWindow()
}
