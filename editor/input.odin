package editor

import rl "vendor:raylib"
import "core:unicode/utf8"
import "../buffer"
import "../cursor"

key_active :: proc(key: rl.KeyboardKey) -> bool {
    return rl.IsKeyPressed(key) || rl.IsKeyPressedRepeat(key)
}

editor_handle_input :: proc(state: ^Editor_State) {
    ctrl         := rl.IsKeyDown(.LEFT_CONTROL)  || rl.IsKeyDown(.RIGHT_CONTROL)
    shift        := rl.IsKeyDown(.LEFT_SHIFT)    || rl.IsKeyDown(.RIGHT_SHIFT)
    alt          := rl.IsKeyDown(.LEFT_ALT)      || rl.IsKeyDown(.RIGHT_ALT)
    cursor_before := state.cursor.head

    // chord commands via keymap (fires once per press, no repeat)
    for {
        key := rl.GetKeyPressed()
        if key == {} do break
        chord := Key_Chord{key = key, ctrl = ctrl, shift = shift, alt = alt}
        if cmd, ok := state.keymap[chord]; ok {
            execute_command(state, cmd)
        }
    }

    if key_active(.UP) && !ctrl && !alt {
        state.cursor = cursor.cursor_move_up(state.cursor, &state.buff, shift)
    }
    if key_active(.DOWN) && !ctrl && !alt {
        state.cursor = cursor.cursor_move_down(state.cursor, &state.buff, shift)
    }
    if key_active(.LEFT) {
        if ctrl {
            state.cursor = cursor.cursor_move_word_left(state.cursor, &state.buff, shift)
        } else {
            state.cursor = cursor.cursor_move_left(state.cursor, &state.buff, shift)
        }
    }
    if key_active(.RIGHT) {
        if ctrl {
            state.cursor = cursor.cursor_move_word_right(state.cursor, &state.buff, shift)
        } else {
            state.cursor = cursor.cursor_move_right(state.cursor, &state.buff, shift)
        }
    }
    if key_active(.HOME) {
        if ctrl {
            state.cursor = cursor.cursor_move_file_start(state.cursor, &state.buff, shift)
        } else {
            state.cursor = cursor.cursor_move_line_start(state.cursor, &state.buff, shift)
        }
    }
    if key_active(.END) {
        if ctrl {
            state.cursor = cursor.cursor_move_file_end(state.cursor, &state.buff, shift)
        } else {
            state.cursor = cursor.cursor_move_line_end(state.cursor, &state.buff, shift)
        }
    }

    // backspace: delete char before cursor
    if key_active(.BACKSPACE) && state.cursor.head > 0 {
        buffer.buffer_delete(&state.buff, state.cursor.head - 1, 1)
        state.cursor = cursor.cursor_move_left(state.cursor, &state.buff, false)
    }

    // delete: delete char at cursor
    if key_active(.DELETE) && state.cursor.head < len(state.buff.data) {
        buffer.buffer_delete(&state.buff, state.cursor.head, 1)
        state.cursor.head   = min(state.cursor.head, max(len(state.buff.data) - 1, 0))
        state.cursor.anchor = state.cursor.head
    }

    // text insertion (only when no ctrl/alt modifier)
    if !ctrl && !alt {
        for {
            char := rl.GetCharPressed()
            if char == 0 do break
            buf, n := utf8.encode_rune(char)
            buffer.buffer_insert(&state.buff, state.cursor.head, buf[:n])
            state.cursor.head  += n
            state.cursor.anchor = state.cursor.head
        }

        if key_active(.ENTER) {
            buffer.buffer_insert(&state.buff, state.cursor.head, []u8{'\n'})
            state.cursor.head  += 1
            state.cursor.anchor = state.cursor.head
        }

        if key_active(.TAB) {
            if state.config.use_spaces {
                n := min(state.config.tab_size, 8)
                spaces: [8]u8
                for i in 0..<n { spaces[i] = ' ' }
                buffer.buffer_insert(&state.buff, state.cursor.head, spaces[:n])
                state.cursor.head  += n
            } else {
                buffer.buffer_insert(&state.buff, state.cursor.head, []u8{'\t'})
                state.cursor.head  += 1
            }
            state.cursor.anchor = state.cursor.head
        }
    }

    // mouse wheel / trackpad scroll
    wheel := rl.GetMouseWheelMoveV().y
    if wheel != 0 {
        state.scroll = max(0, state.scroll - int(wheel * 3))
    }

    // scroll follows cursor (only when cursor moved via keyboard)
    if state.cursor.head != cursor_before {
        line          := cursor.cursor_line(state.cursor, &state.buff)
        visible_lines := int(f32(rl.GetScreenHeight()) / state.font.glyph_h)
        if line < state.scroll {
            state.scroll = line
        } else if line >= state.scroll + visible_lines {
            state.scroll = line - visible_lines + 1
        }
    }
}
