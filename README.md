# Buffed

A minimal, fast code editor written in [Odin](https://odin-lang.org/) using [Raylib](https://www.raylib.com/).

## Requirements

- [Odin](https://odin-lang.org/) `dev-2025-11` or later
- Raylib 5.5 (vendored with Odin)

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

All configuration lives in `~/.config/buffed/config.json`:

```json
{
  "font_path": "/usr/share/fonts/TTF/JetBrainsMonoNerdFont-SemiBold.ttf",
  "font_size": 28,
  "theme_path": "~/.config/buffed/themes/gruvbox-dark.theme",
  "keybindings": "~/.config/buffed/keybindings.json",
  "langs_dir": "~/.config/buffed/langs",
  "tab_size": 4,
  "use_spaces": true
}
```

If the config file is missing, built-in defaults are used (embedded at compile time).

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