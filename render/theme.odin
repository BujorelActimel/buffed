package render

import "core:os"
import "core:encoding/json"
import "core:strconv"
import "core:strings"
import "core:mem/virtual"
import "core:fmt"
import rl "vendor:raylib"

import "../config"
import defaults "../default"

Theme :: struct {
    bg:        rl.Color,
    bg_editor: rl.Color,
    bg_select: rl.Color,
    fg:        rl.Color,
    comment:   rl.Color,
    keyword:   rl.Color,
    type_kw:   rl.Color,
    type_c:    rl.Color,
    string_lit:rl.Color,
    number:    rl.Color,
    operator:  rl.Color,
    preproc:   rl.Color,
    function:  rl.Color,
    constant:  rl.Color,
    attribute: rl.Color,
    cursor:    rl.Color,
    line_num:  rl.Color,
    error:     rl.Color,
    warning:   rl.Color,
}

Token_Kind :: enum u8 {
    Normal, Keyword, Type_Keyword, String, Number,
    Comment, Operator, Preprocessor, Function, Constant,
}

@(private)
Theme_Json :: struct {
    bg:         string,
    bg_editor:  string,
    bg_select:  string,
    fg:         string,
    comment:    string,
    keyword:    string,
    type_kw:    string,
    type:       string,
    string_lit: string,
    number:     string,
    operator:   string,
    preproc:    string,
    function:   string,
    constant:   string,
    attribute:  string,
    cursor:     string,
    line_num:   string,
    error:      string,
    warning:    string,
}

theme_parse :: proc(data: []u8) -> (Theme, bool) {
    arena: virtual.Arena
    if err := virtual.arena_init_growing(&arena); err != nil {
        fmt.println("Error creating arena allocator")
        return {}, false
    }
    defer virtual.arena_destroy(&arena)

    raw: Theme_Json
    if err := json.unmarshal(data, &raw, allocator = virtual.arena_allocator(&arena)); err != nil {
        fmt.println("Failed to parse theme JSON:", err)
        return {}, false
    }

    return Theme{
        bg         = hex_to_color(raw.bg),
        bg_editor  = hex_to_color(raw.bg_editor),
        bg_select  = hex_to_color(raw.bg_select),
        fg         = hex_to_color(raw.fg),
        comment    = hex_to_color(raw.comment),
        keyword    = hex_to_color(raw.keyword),
        type_kw    = hex_to_color(raw.type_kw),
        type_c     = hex_to_color(raw.type),
        string_lit = hex_to_color(raw.string_lit),
        number     = hex_to_color(raw.number),
        operator   = hex_to_color(raw.operator),
        preproc    = hex_to_color(raw.preproc),
        function   = hex_to_color(raw.function),
        constant   = hex_to_color(raw.constant),
        attribute  = hex_to_color(raw.attribute),
        cursor     = hex_to_color(raw.cursor),
        line_num   = hex_to_color(raw.line_num),
        error      = hex_to_color(raw.error),
        warning    = hex_to_color(raw.warning),
    }, true
}

theme_load :: proc(conf: config.Config) -> (Theme, bool) {
    if conf.theme_path == "" {
        return theme_parse(defaults.DEFAULT_THEME)
    }

    arena: virtual.Arena
    if err := virtual.arena_init_growing(&arena); err != nil {
        fmt.println("Error creating arena allocator")
        return theme_parse(defaults.DEFAULT_THEME)
    }
    defer virtual.arena_destroy(&arena)
    arena_allocator := virtual.arena_allocator(&arena)

    data, ok := os.read_entire_file(conf.theme_path, arena_allocator)
    if !ok {
        fmt.println("Theme file missing, falling back to embedded default")
        return theme_parse(defaults.DEFAULT_THEME)
    }

    return theme_parse(data)
}

token_color :: proc(t: ^Theme, kind: Token_Kind) -> (color: rl.Color) {
    switch kind {
        case .Keyword:      color = t.keyword
        case .Type_Keyword: color = t.type_kw
        case .String:       color = t.string_lit
        case .Number:       color = t.number
        case .Comment:      color = t.comment
        case .Operator:     color = t.operator
        case .Preprocessor: color = t.preproc
        case .Function:     color = t.function
        case .Constant:     color = t.constant
        case .Normal:       color = t.fg
    }
    return
}

theme_color_for_capture :: proc(t: ^Theme, name: string) -> rl.Color {
    if strings.has_prefix(name, "keyword.type") do return t.type_kw
    if strings.has_prefix(name, "keyword")      do return t.keyword
    if strings.has_prefix(name, "include")      do return t.keyword
    if strings.has_prefix(name, "storageclass") do return t.keyword
    if strings.has_prefix(name, "conditional")  do return t.keyword
    if strings.has_prefix(name, "repeat")       do return t.keyword
    if strings.has_prefix(name, "type")         do return t.type_c
    if strings.has_prefix(name, "string")       do return t.string_lit
    if strings.has_prefix(name, "character")    do return t.string_lit
    if strings.has_prefix(name, "number")       do return t.number
    if strings.has_prefix(name, "float")        do return t.number
    if strings.has_prefix(name, "boolean")      do return t.constant
    if strings.has_prefix(name, "comment")      do return t.comment
    if strings.has_prefix(name, "operator")     do return t.operator
    if strings.has_prefix(name, "function")     do return t.function
    if strings.has_prefix(name, "constructor")  do return t.function
    if strings.has_prefix(name, "escape")       do return t.string_lit
    if strings.has_prefix(name, "variable.builtin") do return t.constant
    if strings.has_prefix(name, "constant")     do return t.constant
    if strings.has_prefix(name, "attribute")    do return t.attribute
    if strings.has_prefix(name, "preproc")      do return t.preproc
    if strings.has_prefix(name, "error")        do return t.error
    return t.fg
}

hex_to_color :: proc(hex: string) -> rl.Color {
    if len(hex) == 0 do return rl.Color{255, 0, 255, 255}
    s := hex[1:]  // strip '#'
    r := u8(strconv.parse_int(s[0:2], 16) or_else 0)
    g := u8(strconv.parse_int(s[2:4], 16) or_else 0)
    b := u8(strconv.parse_int(s[4:6], 16) or_else 0)
    a := u8(255)
    if len(s) == 8 {
        a = u8(strconv.parse_int(s[6:8], 16) or_else 255)
    }
    return rl.Color{r, g, b, a}
}
