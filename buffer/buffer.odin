package buffer

import "core:os"
import "core:strings"

Buffer :: struct {
    data:      [dynamic]u8,
    line_ends: [dynamic]int, // byte offsets of each '\n'
    file_path: string,
    modified:  bool,
    history:   History,
}

buffer_load_file :: proc(path: string) -> (Buffer, bool) {
    data, ok := os.read_entire_file(path)    
    if !ok {
        return {}, false
    }

    line_ends: [dynamic]int
    for i in 0..<len(data) {
        if data[i] == '\n' {
            append(&line_ends, i)
        }
    }
    append(&line_ends, len(data))

    dyn_data := make([dynamic]u8, len(data))
    copy(dyn_data[:], data)
    delete(data)
    file_path := strings.clone(path)

    buff := Buffer{
        data = dyn_data,
        line_ends = line_ends,
        file_path = file_path,
    }

    return buff, true
}

buffer_get_line :: proc(buff: ^Buffer, line: int) -> string {
    if line < 0 || line >= len(buff.line_ends) do return ""

    start := buff.line_ends[line-1]+1 if line > 0 else 0
    end := buff.line_ends[line]

    line_data := buff.data[start:end]

    return string(line_data)
}

buffer_line_count :: proc(buff: ^Buffer) -> int {
    return len(buff.line_ends)
}

buffer_line_start :: proc(buff: ^Buffer, line: int) -> int {
    if line < 0 || line >= len(buff.line_ends) do return -1

    return buff.line_ends[line-1]+1 if line > 0 else 0
}

buffer_line_length :: proc(buff: ^Buffer, line: int) -> int {
    return buff.line_ends[line] - buff.line_ends[line-1] - 1 if line > 0 else buff.line_ends[line]
}

buffer_insert :: proc(buff: ^Buffer, pos: int, data: []u8, record: bool = true) {
    if record {
        for r in buff.history.redo { delete(r.data) }
        clear(&buff.history.redo)
        data_copy := make([]u8, len(data))
        copy(data_copy, data)
        append(&buff.history.undo, Edit_Record{kind = .Insert, pos = pos, data = data_copy})
    }

    n := len(data)
    old_len := len(buff.data)

    resize(&buff.data, old_len + n)
    copy(buff.data[pos+n:], buff.data[pos:old_len])
    copy(buff.data[pos:], data)

    lo, hi := 0, len(buff.line_ends)
    for lo < hi {
        mid := lo + (hi - lo) / 2
        if buff.line_ends[mid] < pos {
            lo = mid + 1
        } else {
            hi = mid
        }
    }
    insert_idx := lo

    for i in insert_idx..<len(buff.line_ends) {
        buff.line_ends[i] += n
    }

    for i in 0..<n {
        if data[i] == '\n' {
            inject_at(&buff.line_ends, insert_idx, pos + i)
            insert_idx += 1
        }
    }

    buff.modified = true
}

buffer_delete :: proc(buff: ^Buffer, pos: int, count: int, record: bool = true) {
    if record {
        for r in buff.history.redo { delete(r.data) }
        clear(&buff.history.redo)
        data_copy := make([]u8, count)
        copy(data_copy, buff.data[pos:pos+count])
        append(&buff.history.undo, Edit_Record{kind = .Delete, pos = pos, data = data_copy})
    }

    copy(buff.data[pos:], buff.data[pos+count:])
    resize(&buff.data, len(buff.data) - count)

    lo, hi := 0, len(buff.line_ends)
    for lo < hi {
        mid := lo + (hi - lo) / 2
        if buff.line_ends[mid] < pos {
            lo = mid + 1
        } else {
            hi = mid
        }
    }
    start_idx := lo

    lo, hi = start_idx, len(buff.line_ends)
    for lo < hi {
        mid := lo + (hi - lo) / 2
        if buff.line_ends[mid] < pos + count {
            lo = mid + 1
        } else {
            hi = mid
        }
    }
    end_idx := lo

    if end_idx > start_idx {
        copy(buff.line_ends[start_idx:], buff.line_ends[end_idx:])
        resize(&buff.line_ends, len(buff.line_ends) - (end_idx - start_idx))
    }

    for i in start_idx..<len(buff.line_ends) {
        buff.line_ends[i] -= count
    }

    buff.modified = true
}

buffer_destroy :: proc(buff: ^Buffer) {
    delete(buff.data)
    delete(buff.line_ends)
    delete(buff.file_path)
    history_destroy(&buff.history)
}
