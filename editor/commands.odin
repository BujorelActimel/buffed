package editor

import "../buffer"

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

execute_command :: proc(state: ^Editor_State, cmd: Command) {
    switch cmd {
    case .Undo:
        buffer.buffer_undo(&state.buff)
    case .Redo:
        buffer.buffer_redo(&state.buff)
    case .Save:
        // TODO: buffer_save_file
    case .Copy:             // TODO: multi-cursor phase
    case .Cut:              // TODO: multi-cursor phase
    case .Paste:            // TODO: multi-cursor phase
    case .Delete_Line:      // TODO: input phase
    case .Select_Next_Occurrence: // TODO: multi-cursor phase
    case .Move_Word_Left:   // TODO: input phase
    case .Move_Word_Right:  // TODO: input phase
    case .Open_Fuzzy_Finder:// TODO: fuzzy phase
    case .Go_To_Definition: // TODO: LSP phase
    case .Add_Cursor_Above: // TODO: multi-cursor phase
    case .Add_Cursor_Below: // TODO: multi-cursor phase
    case .Toggle_File_Tree: // TODO: file tree phase
    }
}
