package render

import rl "vendor:raylib"
import "core:strings"
import "../config"
import defaults "../default"

Font_Info :: struct {
    font:    rl.Font,
    glyph_w: f32,
    glyph_h: f32,
}

font_load :: proc(conf: config.Config) -> Font_Info {
    size := conf.font_size if conf.font_size > 0 else config.DEFAULT_CONFIG.font_size

    font: rl.Font
    if conf.font_path == "" {
        font = rl.LoadFontFromMemory(
            ".ttf",
            raw_data(defaults.DEFAULT_FONT),
            i32(len(defaults.DEFAULT_FONT)),
            i32(size),
            nil, 0,
        )
    } else {
        path := strings.clone_to_cstring(conf.font_path)
        defer delete(path)
        font = rl.LoadFontEx(path, i32(size), nil, 0)
    }

    glyph_w := rl.GetGlyphInfo(font, '0').advanceX
    glyph_h := font.baseSize
    return Font_Info{
        font    = font,
        glyph_w = f32(glyph_w),
        glyph_h = f32(glyph_h),
    }
}
