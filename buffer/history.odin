package buffer

Edit_Kind :: enum { Insert, Delete }

Edit_Record :: struct {
    kind: Edit_Kind,
    pos:  int,
    data: []u8,
}

History :: struct {
    undo: [dynamic]Edit_Record,
    redo: [dynamic]Edit_Record,
}

history_destroy :: proc(h: ^History) {
    for r in h.undo { delete(r.data) }
    for r in h.redo { delete(r.data) }
    delete(h.undo)
    delete(h.redo)
}

buffer_undo :: proc(buff: ^Buffer) -> bool {
    if len(buff.history.undo) == 0 do return false

    record := pop(&buff.history.undo)
    append(&buff.history.redo, record)

    switch record.kind {
    case .Insert:
        buffer_delete(buff, record.pos, len(record.data), record = false)
    case .Delete:
        buffer_insert(buff, record.pos, record.data, record = false)
    }

    return true
}

buffer_redo :: proc(buff: ^Buffer) -> bool {
    if len(buff.history.redo) == 0 do return false

    record := pop(&buff.history.redo)
    append(&buff.history.undo, record)

    switch record.kind {
    case .Insert:
        buffer_insert(buff, record.pos, record.data, record = false)
    case .Delete:
        buffer_delete(buff, record.pos, len(record.data), record = false)
    }

    return true
}
