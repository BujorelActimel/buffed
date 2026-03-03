package editor

import "core:mem/virtual"
import "core:encoding/json"
import "core:strings"
import "core:os"
import rl "vendor:raylib"
import "../default"

Key_Chord :: struct {
    key:   rl.KeyboardKey,
    ctrl:  bool,
    shift: bool,
    alt:   bool,
}

Keymap :: map[Key_Chord]Command

key_name_to_key :: proc(name: string) -> (rl.KeyboardKey, bool) {
    switch name {
    // special keys
    case "space":              return .Space, true
    case "enter":              return .Enter, true
    case "tab":                return .Tab, true
    case "backspace":          return .Backspace, true
    case "escape", "esc":      return .Escape, true
    case "delete", "del":      return .Delete, true
    case "insert":             return .Insert, true
    case "up":                 return .Up, true
    case "down":               return .Down, true
    case "left":               return .Left, true
    case "right":              return .Right, true
    case "home":               return .Home, true
    case "end":                return .End, true
    case "pageup":             return .Page_Up, true
    case "pagedown":           return .Page_Down, true
    // function keys
    case "f1":                 return .F1, true
    case "f2":                 return .F2, true
    case "f3":                 return .F3, true
    case "f4":                 return .F4, true
    case "f5":                 return .F5, true
    case "f6":                 return .F6, true
    case "f7":                 return .F7, true
    case "f8":                 return .F8, true
    case "f9":                 return .F9, true
    case "f10":                return .F10, true
    case "f11":                return .F11, true
    case "f12":                return .F12, true
    // letters
    case "a":                  return .A, true
    case "b":                  return .B, true
    case "c":                  return .C, true
    case "d":                  return .D, true
    case "e":                  return .E, true
    case "f":                  return .F, true
    case "g":                  return .G, true
    case "h":                  return .H, true
    case "i":                  return .I, true
    case "j":                  return .J, true
    case "k":                  return .K, true
    case "l":                  return .L, true
    case "m":                  return .M, true
    case "n":                  return .N, true
    case "o":                  return .O, true
    case "p":                  return .P, true
    case "q":                  return .Q, true
    case "r":                  return .R, true
    case "s":                  return .S, true
    case "t":                  return .T, true
    case "u":                  return .U, true
    case "v":                  return .V, true
    case "w":                  return .W, true
    case "x":                  return .X, true
    case "y":                  return .Y, true
    case "z":                  return .Z, true
    // digits
    case "0":                  return .Zero, true
    case "1":                  return .One, true
    case "2":                  return .Two, true
    case "3":                  return .Three, true
    case "4":                  return .Four, true
    case "5":                  return .Five, true
    case "6":                  return .Six, true
    case "7":                  return .Seven, true
    case "8":                  return .Eight, true
    case "9":                  return .Nine, true
    // symbols
    case "minus",        "-":  return .Minus, true
    case "equal",        "=":  return .Equal, true
    case "semicolon",    ";":  return .Semicolon, true
    case "apostrophe",   "'":  return .Apostrophe, true
    case "comma",        ",":  return .Comma, true
    case "period",       ".":  return .Period, true
    case "slash",        "/":  return .Slash, true
    case "backslash",   "\\":  return .Backslash, true
    case "grave",        "`":  return .Grave, true
    case "leftbracket",  "[":  return .Left_Bracket, true
    case "rightbracket", "]":  return .Right_Bracket, true
    }
    return .Null, false
}

chord_from_str :: proc(s: string) -> (Key_Chord, bool) {
    arena: virtual.Arena
    _ = virtual.arena_init_growing(&arena)
    defer virtual.arena_destroy(&arena)
    arena_allocator := virtual.arena_allocator(&arena)

    parts, _ := strings.split(s, "+", arena_allocator)

    chord: Key_Chord
    for part in parts {
        lower := strings.to_lower(part, arena_allocator)
        switch lower {
        case "ctrl":  chord.ctrl  = true
        case "shift": chord.shift = true
        case "alt":   chord.alt   = true
        case:
            key, ok := key_name_to_key(lower)
            if !ok do return {}, false
            chord.key = key
        }
    }

    return chord, true
}

command_from_str :: proc(s: string) -> (Command, bool) {
    switch s {
    case "copy":                    return .Copy, true
    case "cut":                     return .Cut, true
    case "paste":                   return .Paste, true
    case "undo":                    return .Undo, true
    case "redo":                    return .Redo, true
    case "save", "save_file":       return .Save, true
    case "delete_line":             return .Delete_Line, true
    case "select_next_occurrence":  return .Select_Next_Occurrence, true
    case "move_word_left":          return .Move_Word_Left, true
    case "move_word_right":         return .Move_Word_Right, true
    case "open_fuzzy_finder":       return .Open_Fuzzy_Finder, true
    case "go_to_definition":        return .Go_To_Definition, true
    case "add_cursor_above":        return .Add_Cursor_Above, true
    case "add_cursor_below":        return .Add_Cursor_Below, true
    case "toggle_file_tree":        return .Toggle_File_Tree, true
    }
    return {}, false
}

keymap_default :: proc() -> Keymap {
    m: Keymap

    arena: virtual.Arena
    _ = virtual.arena_init_growing(&arena)
    defer virtual.arena_destroy(&arena)
    arena_allocator := virtual.arena_allocator(&arena)

    raw: map[string]string
    if err := json.unmarshal(default.DEFAULT_KEYBINDINGS, &raw, allocator = arena_allocator); err != nil {
        return m
    }

    for chord_str, cmd_str in raw {
        chord, ok1 := chord_from_str(chord_str)
        cmd,   ok2 := command_from_str(cmd_str)
        if ok1 && ok2 {
            m[chord] = cmd
        }
    }

    return m
}

keymap_load :: proc(path: string) -> Keymap {
    m := keymap_default()

    arena: virtual.Arena
    _ = virtual.arena_init_growing(&arena)
    defer virtual.arena_destroy(&arena)
    arena_allocator := virtual.arena_allocator(&arena)

    data, ok := os.read_entire_file(path, arena_allocator)
    if !ok do return m

    raw: map[string]string
    if err := json.unmarshal(data, &raw, allocator = arena_allocator); err != nil {
        return m
    }

    for chord_str, cmd_str in raw {
        chord, ok1 := chord_from_str(chord_str)
        cmd,   ok2 := command_from_str(cmd_str)
        if ok1 && ok2 {
            m[chord] = cmd
        }
    }

    return m
}
