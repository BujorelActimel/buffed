# Buffed

A minimal, fast code editor written in [Odin](https://odin-lang.org/) using [Raylib](https://www.raylib.com/).

## Requirements

- [Odin](https://odin-lang.org/) `dev-2026-03` or later
- Raylib 5.5 (vendored with Odin)

## Setup

Install tree-sitter and the default language grammars (one-time):

```bash
git clone https://github.com/laytan/odin-tree-sitter vendor/tree-sitter
odin run vendor/tree-sitter/build -- install
odin run vendor/tree-sitter/build -- install-parser https://github.com/tree-sitter-grammars/tree-sitter-odin
odin run vendor/tree-sitter/build -- install-parser https://github.com/tree-sitter/tree-sitter-c
odin run vendor/tree-sitter/build -- install-parser https://github.com/tree-sitter/tree-sitter-rust
odin run vendor/tree-sitter/build -- install-parser https://github.com/tree-sitter/tree-sitter-go
odin run vendor/tree-sitter/build -- install-parser https://github.com/tree-sitter/tree-sitter-python
odin run vendor/tree-sitter/build -- install-parser https://github.com/tree-sitter/tree-sitter-json
```

To add more languages, find the parser at the [tree-sitter parser list](https://github.com/tree-sitter/tree-sitter/wiki/List-of-parsers) and run `install-parser` with its URL.

## Build

```bash
# debug
odin build . -out:buffed-debug -debug

# release
odin build . -out:buffed -o:speed
```

## Usage

```bash
./buffed path/to/file.odin
```

## Configuration

All configuration lives in `~/.config/buffed/config.json`. If the file is missing, built-in defaults are used (embedded at compile time).

```json
{
  "font_path":  "/usr/share/fonts/TTF/JetBrainsMonoNerdFont-SemiBold.ttf",
  "font_size":  28,
  "theme_path": "/home/you/.config/buffed/themes/my-theme.theme.json",
  "tab_size":   4,
  "use_spaces": true
}
```

| Field | Default | Description |
|-------|---------|-------------|
| `font_path` | bundled JetBrains Mono | Absolute path to a `.ttf` font file |
| `font_size` | `28` | Font size in pixels |
| `theme_path` | bundled Gruvbox Dark | Absolute path to a `.theme.json` file |
| `tab_size` | `4` | Number of spaces per tab stop |
| `use_spaces` | `true` | Insert spaces on Tab; `false` inserts a literal `\t` |

> **Note:** paths must be absolute, `~` is not expanded.

### Custom themes

Create a `.theme.json` file anywhere and point `theme_path` at it:

```json
{
  "bg":        "#1a1b26",
  "bg_editor": "#24283b",
  "bg_select": "#2e3458",
  "fg":        "#c0caf5",
  "comment":   "#565f89",
  "keyword":   "#bb9af7",
  "type_kw":   "#2ac3de",
  "type":      "#2ac3de",
  "string_lit":"#9ece6a",
  "number":    "#ff9e64",
  "operator":  "#89ddff",
  "preproc":   "#7dcfff",
  "function":  "#7aa2f7",
  "constant":  "#ff9e64",
  "attribute": "#bb9af7",
  "cursor":    "#c0caf5",
  "line_num":  "#3b4261",
  "error":     "#f7768e",
  "warning":   "#e0af68"
}
```

| Field | Used for |
|-------|----------|
| `bg` | Window chrome, top bar, status bar, side tree |
| `bg_editor` | Editor background |
| `bg_select` | Selection highlight |
| `fg` | Default text |
| `comment` | Comments |
| `keyword` | Keywords (`if`, `for`, `return`, …) |
| `type_kw` | Built-in type keywords (`int`, `bool`, …) |
| `type` | User-defined types and structs |
| `string_lit` | String literals |
| `number` | Numeric literals |
| `operator` | Operators |
| `preproc` | Preprocessor directives |
| `function` | Function and method names |
| `constant` | Constants and enum values |
| `attribute` | Attributes and decorators |
| `cursor` | Block cursor fill |
| `line_num` | Gutter line numbers |
| `error` | Error diagnostics |
| `warning` | Warning diagnostics |

## Keybindings

| Key | Action |
|-----|--------|
| Ctrl+S | Save file |
| Ctrl+Z | Undo |
| Ctrl+Shift+Z | Redo |
| Ctrl+Left/Right | Move by word |
| Home / End | Line start / end |
| Ctrl+Home / Ctrl+End | File start / end |
| Ctrl+Shift+K | Delete line |
| Ctrl+P | Fuzzy finder |
| Ctrl+D | Select next occurrence |
| F12 | Go to definition |

Keybindings are fully remappable via `~/.config/buffed/keybindings.json`.
