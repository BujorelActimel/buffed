package render

import rl "vendor:raylib"

Layout :: struct {
    top_bar_h: i32, 
    status_bar_h: i32, 
    side_tree_w: i32, 
    gutter_w: i32,
    top_bar: rl.Rectangle,
    side_tree: rl.Rectangle,
    gutter: rl.Rectangle,
    editor: rl.Rectangle,
    status_bar: rl.Rectangle,
}

layout_compute :: proc(screen_w, screen_h: i32, font: ^Font_Info, side_tree_open: bool) -> Layout {
    l: Layout

    l.top_bar_h    = i32(font.glyph_h) + 8
    l.status_bar_h = i32(font.glyph_h) + 4
    l.side_tree_w  = 220 if side_tree_open else 0
    l.gutter_w     = i32(font.glyph_w) * 5

    content_y := l.top_bar_h
    content_h := screen_h - l.top_bar_h - l.status_bar_h

    l.top_bar    = {0,                             0,                  f32(screen_w),                         f32(l.top_bar_h)}
    l.side_tree  = {0,                             f32(content_y),     f32(l.side_tree_w),                    f32(content_h)}
    l.gutter     = {f32(l.side_tree_w),            f32(content_y),     f32(l.gutter_w),                       f32(content_h)}
    l.editor     = {f32(l.side_tree_w+l.gutter_w), f32(content_y),     f32(screen_w-l.side_tree_w-l.gutter_w), f32(content_h)}
    l.status_bar = {0,                             f32(screen_h-l.status_bar_h), f32(screen_w),              f32(l.status_bar_h)}

    return l
}
