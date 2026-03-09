package render

import "core:unicode/utf8"
import "core:strings"
import rl "vendor:raylib"
import "../buffer"
import ts "../vendor/tree-sitter"

render_editor :: proc(buf: ^buffer.Buffer, font: ^Font_Info, theme: ^Theme, layout: Layout, cursor_head: int, scroll: int, tab_size: int) {
    rl.DrawRectangleRec(layout.editor, theme.bg_editor)

    rl.BeginScissorMode(i32(layout.editor.x), i32(layout.editor.y), i32(layout.editor.width), i32(layout.editor.height))
    defer rl.EndScissorMode()

    line_count    := buffer.buffer_line_count(buf)
    visible_lines := int(layout.editor.height / font.glyph_h) + 2
    first_line    := scroll
    last_line     := min(line_count, first_line + visible_lines)

    // syntax highlight setup
    qcursor:   ts.Query_Cursor
    syn_query: ts.Query
    use_syntax := false

    if syn, ok := buf.syntax.?; ok {
        use_syntax = true
        syn_query  = syn.query
        qcursor    = ts.query_cursor_new()
        start_byte := u32(buffer.buffer_line_start(buf, first_line))
        end_byte   := u32(buf.line_ends[last_line - 1])
        ts.query_cursor_set_byte_range(qcursor, start_byte, end_byte)
        ts.query_cursor_exec(qcursor, syn_query, ts.tree_root_node(syn.tree))
    }
    defer if use_syntax { ts.query_cursor_delete(qcursor) }

    // two-slot capture state: cap = current, nxt = lookahead
    // when multiple captures overlap at the same position, highest priority wins
    cap_start, cap_end: u32
    cap_name  := ""
    cap_color := theme.fg
    cap_done  := !use_syntax
    nxt_start, nxt_end: u32
    nxt_name  := ""
    nxt_color := theme.fg
    nxt_done  := !use_syntax

    promote :: proc(cap_name: ^string, cap_color: ^rl.Color, nxt_name: string, nxt_color: rl.Color) {
        if capture_priority(nxt_name) > capture_priority(cap_name^) {
            cap_name^  = nxt_name
            cap_color^ = nxt_color
        }
    }

    if use_syntax {
        cap_start, cap_end, cap_name, cap_color, cap_done = next_capture(qcursor, syn_query, theme)
        nxt_start, nxt_end, nxt_name, nxt_color, nxt_done = next_capture(qcursor, syn_query, theme)
        for !nxt_done && nxt_start == cap_start {
            promote(&cap_name, &cap_color, nxt_name, nxt_color)
            nxt_start, nxt_end, nxt_name, nxt_color, nxt_done = next_capture(qcursor, syn_query, theme)
        }
    }

    for i in first_line..<last_line {
        line     := buffer.buffer_get_line(buf, i)
        y        := layout.editor.y + f32(i - scroll) * font.glyph_h
        byte_pos := u32(buffer.buffer_line_start(buf, i))
        x: f32    = layout.editor.x

        for ch in line {
            // advance past expired captures
            for !cap_done && byte_pos >= cap_end {
                cap_start, cap_end, cap_name, cap_color, cap_done = nxt_start, nxt_end, nxt_name, nxt_color, nxt_done
                if !nxt_done {
                    nxt_start, nxt_end, nxt_name, nxt_color, nxt_done = next_capture(qcursor, syn_query, theme)
                    for !nxt_done && nxt_start == cap_start {
                        promote(&cap_name, &cap_color, nxt_name, nxt_color)
                        nxt_start, nxt_end, nxt_name, nxt_color, nxt_done = next_capture(qcursor, syn_query, theme)
                    }
                }
            }

            color := theme.fg
            if !cap_done && byte_pos >= cap_start && byte_pos < cap_end {
                color = cap_color
            }

            if ch == '\t' {
                x += font.glyph_w * f32(tab_size)
            } else {
                rl.DrawTextCodepoint(font.font, ch, rl.Vector2{x, y}, font.glyph_h, color)
                x += font.glyph_w
            }
            byte_pos += u32(utf8.rune_size(ch))
        }
    }

    // block cursor
    cursor_line := buffer_cursor_line(buf, cursor_head)
    cursor_col  := cursor_head - buffer.buffer_line_start(buf, cursor_line)
    cursor_x    := layout.editor.x + f32(cursor_col) * font.glyph_w
    cursor_y    := layout.editor.y + f32(cursor_line - scroll) * font.glyph_h

    rl.DrawRectangleV(
        rl.Vector2{cursor_x, cursor_y},
        rl.Vector2{font.glyph_w, font.glyph_h},
        theme.cursor,
    )
    if cursor_head < len(buf.data) {
        ch := rune(buf.data[cursor_head])
        if ch != '\n' {
            rl.DrawTextCodepoint(font.font, ch, rl.Vector2{cursor_x, cursor_y}, font.glyph_h, theme.bg_editor)
        }
    }
}

next_capture :: proc(qcursor: ts.Query_Cursor, query: ts.Query, theme: ^Theme) -> (start, end: u32, name: string, color: rl.Color, done: bool) {
    for {
        match, cap_idx, ok := ts.query_cursor_next_capture(qcursor)
        if !ok do return 0, 0, "", theme.fg, true
        if pattern_has_filter_predicates(query, u32(match.pattern_index)) do continue
        cap  := match.captures[cap_idx]
        n    := ts.query_capture_name_for_id(query, cap.index)
        return ts.node_start_byte(cap.node), ts.node_end_byte(cap.node), n, theme_color_for_capture(theme, n), false
    }
}

// Higher number = wins when captures overlap at the same position.
// Mirrors Neovim's treesitter priority convention.
capture_priority :: proc(name: string) -> int {
    switch {
    case strings.has_prefix(name, "keyword"):   return 8
    case strings.has_prefix(name, "number"),
         strings.has_prefix(name, "float"),
         strings.has_prefix(name, "string"),
         strings.has_prefix(name, "character"),
         strings.has_prefix(name, "comment"):   return 7
    case strings.has_prefix(name, "type"),
         strings.has_prefix(name, "function"),
         strings.has_prefix(name, "constant"),
         strings.has_prefix(name, "operator"),
         strings.has_prefix(name, "preproc"):   return 6
    case strings.has_prefix(name, "attribute"),
         strings.has_prefix(name, "property"),
         strings.has_prefix(name, "field"),
         strings.has_prefix(name, "namespace"): return 4
    case strings.has_prefix(name, "parameter"): return 3
    case strings.has_prefix(name, "variable"):  return 2
    }
    return 5
}

// Skip patterns with filter predicates we don't evaluate (anything other than #set!).
// Without filtering, patterns like `(#lua-match? @constant "^[A-Z]...")` match every
// identifier because tree-sitter's C API ignores predicates and returns all matches.
@(private)
pattern_has_filter_predicates :: proc(query: ts.Query, pattern_index: u32) -> bool {
    steps := ts.query_predicates_for_pattern(query, pattern_index)
    predicate_start := true
    for step in steps {
        if step.type == .Done {
            predicate_start = true
            continue
        }
        if predicate_start && step.type == .String {
            predicate_start = false
            name := ts.query_string_value_for_id(query, step.value_id)
            if name != "set!" && name != "is?" && name != "is-not?" {
                return true
            }
        } else {
            predicate_start = false
        }
    }
    return false
}

// binary search - mirrors cursor_line from the cursor package
// kept here to avoid a circular import (render → cursor → buffer → render)
buffer_cursor_line :: proc(buf: ^buffer.Buffer, pos: int) -> int {
    lo, hi := 0, len(buf.line_ends) - 1
    for lo < hi {
        mid := lo + (hi - lo) / 2
        if buf.line_ends[mid] < pos {
            lo = mid + 1
        } else {
            hi = mid
        }
    }
    return lo
}
