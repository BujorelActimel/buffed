package cursor

import "../buffer"

Selection :: struct {
    anchor: int,
    head: int,
}

Cursor_List :: struct {
    items: [dynamic]Selection, 
    primary: int,
}

cursor_line :: proc(cursor: Selection, buff: ^buffer.Buffer) -> int {
    pos := cursor.head
    lo, hi := 0, len(buff.line_ends) - 1
    
    for lo < hi {
        mid := lo + (hi - lo) / 2
        if buff.line_ends[mid] < pos {
            lo = mid + 1
        } else {
            hi = mid
        }
    }

    return lo
}

cursor_col :: proc(cursor: Selection, buff: ^buffer.Buffer) -> int {
    line := cursor_line(cursor, buff)
    line_start := buff.line_ends[line - 1] + 1 if line > 0 else 0
    return cursor.head - line_start
}

cursor_move_left :: proc(
    cursor: Selection, 
    buff: ^buffer.Buffer, 
    keep_anchor: bool = false,
) -> Selection {
    new_head := cursor.head - 1 if cursor.head > 0 else 0
    return Selection{
        anchor = new_head if !keep_anchor else cursor.anchor,
        head = new_head,
    }
}

cursor_move_right :: proc(
    cursor: Selection, 
    buff: ^buffer.Buffer, 
    keep_anchor: bool = false,
) -> Selection {
    limit := len(buff.data)-1
    new_head := cursor.head + 1 if cursor.head < limit else limit
    return Selection{
        anchor = new_head if !keep_anchor else cursor.anchor,
        head = new_head,
    }
}

cursor_move_up :: proc(
    cursor: Selection, 
    buff: ^buffer.Buffer, 
    keep_anchor: bool = false,
) -> Selection {
    line := cursor_line(cursor, buff)

    if line == 0 do return cursor

    col := cursor_col(cursor, buff)

    target_line_len := buffer.buffer_line_length(buff, line-1)
    clamped_col := min(col, target_line_len)
    new_head := buffer.buffer_line_start(buff, line-1) + clamped_col

    return Selection{
        anchor = new_head if !keep_anchor else cursor.anchor,
        head = new_head,
    }
}

cursor_move_down :: proc(
    cursor: Selection,
    buff: ^buffer.Buffer,
    keep_anchor: bool = false,
) -> Selection {
    line := cursor_line(cursor, buff)

    if line == buffer.buffer_line_count(buff) - 1 do return cursor

    col := cursor_col(cursor, buff)

    target_line_len := buffer.buffer_line_length(buff, line+1)
    clamped_col := min(col, target_line_len)
    new_head := buffer.buffer_line_start(buff, line+1) + clamped_col

    return Selection{
        anchor = new_head if !keep_anchor else cursor.anchor,
        head = new_head,
    }
}

cursor_move_word_left :: proc(
    cursor: Selection, 
    buff: ^buffer.Buffer, 
    keep_anchor: bool = false,
) -> Selection {
    if cursor.head == 0 do return cursor

    pos := cursor.head - 1

    for pos > 0 && !is_alpha(buff.data[pos]) {
        pos -= 1
    }

    for pos > 0 && is_alpha(buff.data[pos - 1]) {
        pos -= 1
    }

    return Selection{
        anchor = pos if !keep_anchor else cursor.anchor,
        head = pos,
    }
}

cursor_move_word_right :: proc(
    cursor: Selection, 
    buff: ^buffer.Buffer, 
    keep_anchor: bool = false,
) -> Selection {
    limit := len(buff.data)-1

    if cursor.head == limit  do return cursor

    pos := cursor.head

    for pos < limit && is_alpha(buff.data[pos]) {
        pos += 1
    }

    for pos < limit && !is_alpha(buff.data[pos]) {
        pos += 1
    }

    return Selection{
        anchor = pos if !keep_anchor else cursor.anchor,
        head = pos,
    }
}

cursor_move_line_start :: proc(
    cursor: Selection, 
    buff: ^buffer.Buffer, 
    keep_anchor: bool = false,
) -> Selection {
    line_start := buffer.buffer_line_start(buff, cursor_line(cursor, buff))
    return Selection{
        anchor = line_start if !keep_anchor else cursor.anchor,
        head = line_start,
    }
}

cursor_move_line_end :: proc(
    cursor: Selection, 
    buff: ^buffer.Buffer, 
    keep_anchor: bool = false,
) -> Selection {
    line := cursor_line(cursor, buff)
    line_start := buffer.buffer_line_start(buff, line)
    line_end := max(buff.line_ends[line] - 1, line_start)
    return Selection{
        anchor = line_end if !keep_anchor else cursor.anchor,
        head = line_end,
    }
}

cursor_move_file_start :: proc(
    cursor: Selection,
    _: ^buffer.Buffer, 
    keep_anchor: bool = false,
) -> Selection {
    return Selection{
        anchor = 0 if !keep_anchor else cursor.anchor,
        head = 0,
    }
}

cursor_move_file_end :: proc(
    cursor: Selection,
    buff: ^buffer.Buffer, 
    keep_anchor: bool = false,
) -> Selection {
    return Selection{
        anchor = len(buff.data)-1 if !keep_anchor else cursor.anchor,
        head = len(buff.data)-1,
    }
}

is_alpha :: proc(char: u8) -> bool {
    return (char >= 'a' && char <= 'z') ||
           (char >= 'A' && char <= 'Z') ||
           (char >= '0' && char <= '9') ||
           char == '_'
}
