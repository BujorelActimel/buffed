package render

import rl "vendor:raylib"

render_splash :: proc(layout: Layout, theme: ^Theme) {
    rl.DrawRectangleRec(layout.gutter, theme.bg_editor)
    rl.DrawRectangleRec(layout.editor, theme.bg_editor)

    @(static) texture: rl.Texture2D
    @(static) loaded: bool

    if !loaded {
        data :: #load("../assets/splash2.png")
        img := rl.LoadImageFromMemory(".png", raw_data(data), i32(len(data)))
        texture = rl.LoadTextureFromImage(img)
        rl.UnloadImage(img)
        loaded = true
    }

    scale :: f32(0.65)
    x := layout.editor.x + (layout.editor.width  - f32(texture.width)  * scale) * 0.5
    y := layout.editor.y + (layout.editor.height - f32(texture.height) * scale) * 0.1
    rl.DrawTextureEx(texture, {x, y}, 0, scale, rl.WHITE)
}
