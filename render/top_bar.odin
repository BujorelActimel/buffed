package render

import rl "vendor:raylib"

SEPARATOR :: rl.Color{255, 255, 255, 40}

TAB_PAD_X :: f32(16)

Tab_Info :: struct {
    name:     string,
    modified: bool,
}

render_top_bar :: proc(
    layout: Layout, 
    font: ^Font_Info, 
    theme: ^Theme, 
    tabs: []Tab_Info, 
    active: int, 
    logo_color1, 
    logo_color2: rl.Color
) {
    rl.DrawRectangleRec(layout.top_bar, theme.bg)

    text_y := layout.top_bar.y + (layout.top_bar.height - font.glyph_h) / 2

    logo   := "Buff-Ed"
    logo_w := f32(len(logo)) * font.glyph_w + TAB_PAD_X * 2
    lx     := layout.top_bar.x + TAB_PAD_X
    for ch, i in logo {
        color := logo_color1 if i < 5 else logo_color2
        rl.DrawTextCodepoint(font.font, ch, {lx, text_y}, font.glyph_h, color)
        lx += font.glyph_w
    }
    rl.DrawRectangle(i32(logo_w) - 1, i32(layout.top_bar.y), 1, i32(layout.top_bar.height), SEPARATOR)

    x := layout.top_bar.x + logo_w

    for i in 0..<len(tabs) {
        tab := tabs[i]
        name := tab.name if len(tab.name) > 0 else "untitled"

        label_w := f32(len(name)) * font.glyph_w
        if tab.modified do label_w += font.glyph_w * 2 // " •"
        tab_w := label_w + TAB_PAD_X * 2

        tab_rect := rl.Rectangle{x, layout.top_bar.y, tab_w, layout.top_bar.height}

        if i == active {
            rl.DrawRectangleRec(tab_rect, theme.bg_editor)
            rl.DrawRectangle(i32(x), i32(layout.top_bar.y), i32(tab_w), 2, theme.keyword)
        }

        fg := theme.fg if i == active else rl.ColorAlpha(theme.fg, 0.5)

        cx := x + TAB_PAD_X
        for ch in name {
            rl.DrawTextCodepoint(font.font, ch, {cx, text_y}, font.glyph_h, fg)
            cx += font.glyph_w
        }
        if tab.modified {
            rl.DrawTextCodepoint(font.font, ' ', {cx, text_y}, font.glyph_h, fg)
            cx += font.glyph_w
            rl.DrawTextCodepoint(font.font, '*', {cx, text_y}, font.glyph_h, theme.warning)
        }

        rl.DrawRectangle(i32(x + tab_w) - 1, i32(layout.top_bar.y), 1, i32(layout.top_bar.height), SEPARATOR)
        x += tab_w
    }

    // bottom border
    rl.DrawRectangle(0, i32(layout.top_bar.height) - 1, i32(layout.top_bar.width), 1, SEPARATOR)
}
