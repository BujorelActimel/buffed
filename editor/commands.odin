package editor

import "core:strings"
import "../buffer"
import "../cursor"

Command :: enum {
    Copy,
    Cut,
    Paste,
    Undo,
    Redo,
    Save,
    Delete_Line,
    Select_Next_Occurrence,
    Move_Word_Left,
    Move_Word_Right,
    Open_Fuzzy_Finder,
    Go_To_Definition,
    Add_Cursor_Above,
    Add_Cursor_Below,
    Toggle_File_Tree,
    New_Buffer,
    Open_Buffer,
    Close_Buffer,
    Next_Buffer,
    Prev_Buffer,
}

editor_delete_line :: proc(state: ^Editor_State) {
    view := &state.views[state.active_view]
    line       := cursor.cursor_line(view.cursor, &view.buf)
    line_start := buffer.buffer_line_start(&view.buf, line)
    line_len   := buffer.buffer_line_length(&view.buf, line)
    is_last    := line == buffer.buffer_line_count(&view.buf) - 1
    count      := line_len + 1 if !is_last else line_len
    buffer.buffer_delete(&view.buf, line_start, count)
    new_pos := min(line_start, max(len(view.buf.data) - 1, 0))
    view.cursor = {anchor = new_pos, head = new_pos}
}

execute_command :: proc(state: ^Editor_State, cmd: Command) {
    #partial switch cmd {
    case .Toggle_File_Tree:
        state.side_tree_open = !state.side_tree_open
    case .New_Buffer:
        editor_new(state)
    case .Open_Buffer:
        if path, ok := file_picker_open(); ok {
            editor_open(state, path)
            delete(path)
        }
    case .Close_Buffer:
        editor_close(state)
    case .Next_Buffer:
        editor_next_buffer(state)
    case .Prev_Buffer:
        editor_prev_buffer(state)
    case .Open_Fuzzy_Finder:// TODO: fuzzy phase
    case .Go_To_Definition: // TODO: LSP phase
    case .Add_Cursor_Above: // TODO: multi-cursor phase
    case .Add_Cursor_Below: // TODO: multi-cursor phase
    case .Copy:             // TODO: multi-cursor phase
    case .Cut:              // TODO: multi-cursor phase
    case .Paste:            // TODO: multi-cursor phase
    case .Select_Next_Occurrence: // TODO: multi-cursor phase
    case:
        if len(state.views) == 0 do return
        view := &state.views[state.active_view]
        #partial switch cmd {
        case .Undo:
            if ok, pos := buffer.buffer_undo(&view.buf); ok {
                view.cursor = {anchor = pos, head = pos}
            }
        case .Redo:
            if ok, pos := buffer.buffer_redo(&view.buf); ok {
                view.cursor = {anchor = pos, head = pos}
            }
        case .Save:
            if view.buf.file_path == "" {
                if path, ok := file_picker_save(); ok {
                    view.buf.file_path = strings.clone(path)
                    delete(path)
                    _ = buffer.buffer_save_file(&view.buf)
                }
            } else {
                _ = buffer.buffer_save_file(&view.buf)
            }
        case .Delete_Line:
            editor_delete_line(state)
        case .Move_Word_Left:
            view.cursor = cursor.cursor_move_word_left(view.cursor, &view.buf)
        case .Move_Word_Right:
            view.cursor = cursor.cursor_move_word_right(view.cursor, &view.buf)
        }
    }
}
