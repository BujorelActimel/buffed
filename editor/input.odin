package editor

import rl "vendor:raylib"
import "core:unicode/utf8"
import "../buffer"
import "../cursor"

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

    // navigation with repeat (fires on press and while held)
    if rl.IsKeyPressedRepeat(.UP) && !ctrl && !alt {
        state.cursor = cursor.cursor_move_up(state.cursor, &state.buff, shift)
    }
    if rl.IsKeyPressedRepeat(.DOWN) && !ctrl && !alt {
        state.cursor = cursor.cursor_move_down(state.cursor, &state.buff, shift)
    }
    if rl.IsKeyPressedRepeat(.LEFT) {
        if ctrl {
            state.cursor = cursor.cursor_move_word_left(state.cursor, &state.buff, shift)
        } else {
            state.cursor = cursor.cursor_move_left(state.cursor, &state.buff, shift)
        }
    }
    if rl.IsKeyPressedRepeat(.RIGHT) {
        if ctrl {
            state.cursor = cursor.cursor_move_word_right(state.cursor, &state.buff, shift)
        } else {
            state.cursor = cursor.cursor_move_right(state.cursor, &state.buff, shift)
        }
    }
    if rl.IsKeyPressedRepeat(.HOME) {
        if ctrl {
            state.cursor = cursor.cursor_move_file_start(state.cursor, &state.buff, shift)
        } else {
            state.cursor = cursor.cursor_move_line_start(state.cursor, &state.buff, shift)
        }
    }
    if rl.IsKeyPressedRepeat(.END) {
        if ctrl {
            state.cursor = cursor.cursor_move_file_end(state.cursor, &state.buff, shift)
        } else {
            state.cursor = cursor.cursor_move_line_end(state.cursor, &state.buff, shift)
        }
    }

    // backspace: delete char before cursor
    if rl.IsKeyPressedRepeat(.BACKSPACE) && state.cursor.head > 0 {
        buffer.buffer_delete(&state.buff, state.cursor.head - 1, 1)
        state.cursor = cursor.cursor_move_left(state.cursor, &state.buff, false)
    }

    // delete: delete char at cursor
    if rl.IsKeyPressedRepeat(.DELETE) && state.cursor.head < len(state.buff.data) {
        buffer.buffer_delete(&state.buff, state.cursor.head, 1)
        state.cursor.head  = min(state.cursor.head, max(len(state.buff.data) - 1, 0))
        state.cursor.anchor = state.cursor.head
    }

    // text insertion (only when no ctrl/alt modifier)
    if !ctrl && !alt {
        for {
            char := rl.GetCharPressed()
            if char == 0 do break
            buf: [utf8.UTF_MAX]u8
            n := utf8.encode_rune(buf[:], char)
            buffer.buffer_insert(&state.buff, state.cursor.head, buf[:n])
            state.cursor.head  += n
            state.cursor.anchor = state.cursor.head
        }
    }
}
