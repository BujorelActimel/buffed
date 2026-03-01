package render

import rl "vendor:raylib"
import "core:strings"
import "../config"

Font_Info :: struct {
    font:    rl.Font,
    glyph_w: f32,
    glyph_h: f32,
}

font_load :: proc(conf: config.Config) -> Font_Info {
    path := strings.clone_to_cstring(conf.font_path)
    defer delete(path)
    font := rl.LoadFontEx(path, i32(conf.font_size), nil, 0)
    glyph_w := rl.GetGlyphInfo(font, '0').advanceX
    glyph_h := font.baseSize
    return Font_Info{
        font = font,
        glyph_w = f32(glyph_w),
        glyph_h = f32(glyph_h),
    }
}
