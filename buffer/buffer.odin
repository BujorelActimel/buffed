package buffer

import "core:os"
import "core:strings"
import "core:path/filepath"
import ts "../vendor/tree-sitter"

import ts_odin "../vendor/tree-sitter/parsers/odin"
import ts_json "../vendor/tree-sitter/parsers/json"
import ts_go "../vendor/tree-sitter/parsers/go"
import ts_c "../vendor/tree-sitter/parsers/c"
import ts_rust "../vendor/tree-sitter/parsers/rust"
import ts_python "../vendor/tree-sitter/parsers/python"

Buffer :: struct {
    data:      [dynamic]u8,
    line_ends: [dynamic]int, // byte offsets of each '\n'
    file_path: string,
    modified:  bool,
    history:   History,
    syntax:    Maybe(Syntax),
}

Syntax :: struct {
    parser: ts.Parser,
    tree:   ts.Tree,
    query:  ts.Query,
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

    syntax: Maybe(Syntax)
    lang, highlights, lang_ok := buffer_detect_language(file_path)
    if lang_ok {
        parser := ts.parser_new()
        ts.parser_set_language(parser, lang)
        tree         := ts.parser_parse_string(parser, string(dyn_data[:]))
        query, _, _  := ts.query_new(lang, highlights)
        syntax        = Syntax{parser = parser, tree = tree, query = query}
    }

    buff := Buffer{
        data      = dyn_data,
        line_ends = line_ends,
        file_path = file_path,
        syntax    = syntax,
    }

    return buff, true
}

buffer_destroy :: proc(buff: ^Buffer) {
    delete(buff.data)
    delete(buff.line_ends)
    delete(buff.file_path)
    history_destroy(&buff.history)
    if syn, ok := buff.syntax.?; ok {
        ts.parser_delete(syn.parser)
        ts.tree_delete(syn.tree)
        ts.query_delete(syn.query)
    }
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
    if syn, ok := buff.syntax.?; ok {
        start_point := byte_to_point(pos, buff.line_ends)
        edit := ts.Input_Edit{
            start_byte    = u32(pos),
            old_end_byte  = u32(pos),
            new_end_byte  = u32(pos + n),
            start_point   = start_point,
            old_end_point = start_point,
            new_end_point = byte_to_point(pos + n, buff.line_ends),
        }
        ts.tree_edit(syn.tree, &edit)
        new_tree    := ts.parser_parse_string(syn.parser, string(buff.data[:]), syn.tree)
        ts.tree_delete(syn.tree)
        syn.tree     = new_tree
        buff.syntax  = syn
    }
}

buffer_delete :: proc(buff: ^Buffer, pos: int, count: int, record: bool = true) {
    if record {
        for r in buff.history.redo { delete(r.data) }
        clear(&buff.history.redo)
        data_copy := make([]u8, count)
        copy(data_copy, buff.data[pos:pos+count])
        append(&buff.history.undo, Edit_Record{kind = .Delete, pos = pos, data = data_copy})
    }

    start_point, old_end_point: ts.Point
    if _, ok := buff.syntax.?; ok {
        start_point   = byte_to_point(pos,         buff.line_ends)
        old_end_point = byte_to_point(pos + count,  buff.line_ends)
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
    if syn, ok := buff.syntax.?; ok {
        edit := ts.Input_Edit{
            start_byte    = u32(pos),
            old_end_byte  = u32(pos + count),
            new_end_byte  = u32(pos),
            start_point   = start_point,
            old_end_point = old_end_point,
            new_end_point = start_point,
        }
        ts.tree_edit(syn.tree, &edit)
        new_tree    := ts.parser_parse_string(syn.parser, string(buff.data[:]), syn.tree)
        ts.tree_delete(syn.tree)
        syn.tree     = new_tree
        buff.syntax  = syn
    }
}

buffer_save_file :: proc(buff: ^Buffer) -> bool {
    if buff.file_path == "" {
        return false
    }

    ok := os.write_entire_file(buff.file_path, buff.data[:])
    if ok do buff.modified = false
    return ok
}

byte_to_point :: proc(offset: int, line_ends: [dynamic]int) -> ts.Point {
    lo, hi := 0, len(line_ends)
    for lo < hi {
        mid := lo + (hi - lo) / 2
        if line_ends[mid] < offset {
            lo = mid + 1
        } else {
            hi = mid
        }
    }
    line       := lo
    line_start := line_ends[line-1] + 1 if line > 0 else 0
    return ts.Point{row = u32(line), col = u32(offset - line_start)}
}

buffer_detect_language :: proc(file_path: string) -> (ts.Language, string, bool) {
    ext := filepath.ext(file_path)
    switch ext {
        case ".odin":    return ts_odin.tree_sitter_odin(), ts_odin.HIGHLIGHTS, true
        case ".c", ".h": return ts_c.tree_sitter_c(),       ts_c.HIGHLIGHTS,    true
        case ".rs":      return ts_rust.tree_sitter_rust(),  ts_rust.HIGHLIGHTS,  true
        case ".go":      return ts_go.tree_sitter_go(),      ts_go.HIGHLIGHTS,    true
        case ".py":      return ts_python.tree_sitter_python(), ts_python.HIGHLIGHTS, true
        case ".json":    return ts_json.tree_sitter_json(),  ts_json.HIGHLIGHTS,  true
    }
    return nil, "", false
}
