package buffer

import "core:os"
import "core:strings"

Buffer :: struct {
    data: [dynamic]u8,
    line_ends: [dynamic]int, // byte offsets of each '\n'
    file_path: string,
    modified:  bool,
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

buffer_destroy :: proc(buff: ^Buffer) {
    delete(buff.data)
    delete(buff.line_ends)
    delete(buff.file_path)
}
