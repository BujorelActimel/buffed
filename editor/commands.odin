package editor

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
}

editor_delete_line :: proc(state: ^Editor_State) {
    line       := cursor.cursor_line(state.cursor, &state.buff)
    line_start := buffer.buffer_line_start(&state.buff, line)
    line_len   := buffer.buffer_line_length(&state.buff, line)
    is_last    := line == buffer.buffer_line_count(&state.buff) - 1
    count      := line_len + 1 if !is_last else line_len
    buffer.buffer_delete(&state.buff, line_start, count)
    new_pos := min(line_start, max(len(state.buff.data) - 1, 0))
    state.cursor = {anchor = new_pos, head = new_pos}
}

execute_command :: proc(state: ^Editor_State, cmd: Command) {
    switch cmd {
    case .Undo:
        if ok, pos := buffer.buffer_undo(&state.buff); ok {
            state.cursor = {anchor = pos, head = pos}
        }
    case .Redo:
        if ok, pos := buffer.buffer_redo(&state.buff); ok {
            state.cursor = {anchor = pos, head = pos}
        }
    case .Save:
        _ = buffer.buffer_save_file(&state.buff) // discard result for now
    case .Copy:             // TODO: multi-cursor phase
    case .Cut:              // TODO: multi-cursor phase
    case .Paste:            // TODO: multi-cursor phase
    case .Delete_Line:
        editor_delete_line(state)
    case .Select_Next_Occurrence: // TODO: multi-cursor phase
    case .Move_Word_Left:
        state.cursor = cursor.cursor_move_word_left(state.cursor, &state.buff)
    case .Move_Word_Right:
        state.cursor = cursor.cursor_move_word_right(state.cursor, &state.buff)
    case .Open_Fuzzy_Finder:// TODO: fuzzy phase
    case .Go_To_Definition: // TODO: LSP phase
    case .Add_Cursor_Above: // TODO: multi-cursor phase
    case .Add_Cursor_Below: // TODO: multi-cursor phase
    case .Toggle_File_Tree:
        state.side_tree_open = !state.side_tree_open
    }
}
