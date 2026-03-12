package editor

import rl "vendor:raylib"
import "core:unicode/utf8"
import "../buffer"
import "../cursor"

key_active :: proc(key: rl.KeyboardKey) -> bool {
    return rl.IsKeyPressed(key) || rl.IsKeyPressedRepeat(key)
}

editor_handle_input :: proc(state: ^Editor_State) {
    ctrl  := rl.IsKeyDown(.LEFT_CONTROL)  || rl.IsKeyDown(.RIGHT_CONTROL)
    shift := rl.IsKeyDown(.LEFT_SHIFT)    || rl.IsKeyDown(.RIGHT_SHIFT)
    alt   := rl.IsKeyDown(.LEFT_ALT)      || rl.IsKeyDown(.RIGHT_ALT)

    // chord commands via keymap (fires once per press, no repeat)
    for {
        key := rl.GetKeyPressed()
        if key == {} do break
        chord := Key_Chord{key = key, ctrl = ctrl, shift = shift, alt = alt}
        if cmd, ok := state.keymap[chord]; ok {
            execute_command(state, cmd)
        }
    }

    // repeat-enabled chord commands (held key fires repeatedly)
    if rl.IsKeyPressedRepeat(.B) && ctrl {
        execute_command(state, .Toggle_File_Tree)
    }
    if rl.IsKeyPressedRepeat(.TAB) && ctrl && !shift {
        execute_command(state, .Next_Buffer)
    }
    if rl.IsKeyPressedRepeat(.TAB) && ctrl && shift {
        execute_command(state, .Prev_Buffer)
    }

    if len(state.views) == 0 do return

    view          := &state.views[state.active_view]
    cursor_before := view.cursor.head

    if key_active(.UP) && !ctrl && !alt {
        view.cursor = cursor.cursor_move_up(view.cursor, &view.buf, shift)
    }
    if key_active(.DOWN) && !ctrl && !alt {
        view.cursor = cursor.cursor_move_down(view.cursor, &view.buf, shift)
    }
    if key_active(.LEFT) {
        if ctrl {
            view.cursor = cursor.cursor_move_word_left(view.cursor, &view.buf, shift)
        } else {
            view.cursor = cursor.cursor_move_left(view.cursor, &view.buf, shift)
        }
    }
    if key_active(.RIGHT) {
        if ctrl {
            view.cursor = cursor.cursor_move_word_right(view.cursor, &view.buf, shift)
        } else {
            view.cursor = cursor.cursor_move_right(view.cursor, &view.buf, shift)
        }
    }
    if key_active(.HOME) {
        if ctrl {
            view.cursor = cursor.cursor_move_file_start(view.cursor, &view.buf, shift)
        } else {
            view.cursor = cursor.cursor_move_line_start(view.cursor, &view.buf, shift)
        }
    }
    if key_active(.END) {
        if ctrl {
            view.cursor = cursor.cursor_move_file_end(view.cursor, &view.buf, shift)
        } else {
            view.cursor = cursor.cursor_move_line_end(view.cursor, &view.buf, shift)
        }
    }

    // backspace: delete char before cursor
    if key_active(.BACKSPACE) && view.cursor.head > 0 {
        buffer.buffer_delete(&view.buf, view.cursor.head - 1, 1)
        view.cursor = cursor.cursor_move_left(view.cursor, &view.buf, false)
    }

    // delete: delete char at cursor
    if key_active(.DELETE) && view.cursor.head < len(view.buf.data) {
        buffer.buffer_delete(&view.buf, view.cursor.head, 1)
        view.cursor.head   = min(view.cursor.head, max(len(view.buf.data) - 1, 0))
        view.cursor.anchor = view.cursor.head
    }

    // text insertion (only when no ctrl/alt modifier)
    if !ctrl && !alt {
        for {
            char := rl.GetCharPressed()
            if char == 0 do break
            buf, n := utf8.encode_rune(char)
            buffer.buffer_insert(&view.buf, view.cursor.head, buf[:n])
            view.cursor.head  += n
            view.cursor.anchor = view.cursor.head
        }

        if key_active(.ENTER) {
            buffer.buffer_insert(&view.buf, view.cursor.head, []u8{'\n'})
            view.cursor.head  += 1
            view.cursor.anchor = view.cursor.head
        }

        if key_active(.TAB) {
            if state.config.use_spaces {
                n := min(state.config.tab_size, 8)
                spaces: [8]u8
                for i in 0..<n { spaces[i] = ' ' }
                buffer.buffer_insert(&view.buf, view.cursor.head, spaces[:n])
                view.cursor.head  += n
            } else {
                buffer.buffer_insert(&view.buf, view.cursor.head, []u8{'\t'})
                view.cursor.head  += 1
            }
            view.cursor.anchor = view.cursor.head
        }
    }

    // mouse wheel / trackpad scroll
    wheel := rl.GetMouseWheelMoveV().y
    if wheel != 0 {
        view.scroll = max(0, view.scroll - int(wheel * 3))
    }

    // scroll follows cursor (only when cursor moved via keyboard)
    if view.cursor.head != cursor_before {
        line          := cursor.cursor_line(view.cursor, &view.buf)
        visible_lines := int(f32(rl.GetScreenHeight()) / state.font.glyph_h)
        if line < view.scroll {
            view.scroll = line
        } else if line >= view.scroll + visible_lines {
            view.scroll = line - visible_lines + 1
        }
    }
}
