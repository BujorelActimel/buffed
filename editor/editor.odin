package editor

import rl "vendor:raylib"
import "../config"
import "../render"

Editor_State :: struct {
    config: config.Config,
    theme:  render.Theme,
    font:   render.Font_Info,
}

editor_init :: proc() -> (Editor_State, bool) {
    state: Editor_State

    state.config, _ = config.config_load()

    state.theme, _ = render.theme_load(state.config)

    rl.InitWindow(800, 600, "Buffed")
    rl.SetTargetFPS(60)

    state.font = render.font_load(state.config)

    return state, true
}

editor_destroy :: proc(state: ^Editor_State) {
    config.config_destroy(&state.config)
    rl.UnloadFont(state.font.font)
    rl.CloseWindow()
}
