package config

import "core:mem/virtual"
import "core:path/filepath"
import "core:encoding/json"
import "core:fmt"
import "core:os"

Config :: struct {
    font_path:   string,
    font_size:   int,
    theme_path:  string,
    keybindings: string,
    langs_dir:   string,
    tab_size:    int,
    use_spaces:  bool,
    lsp_servers: map[string][]string,
}

BASE_CONFIG_PATH :: ".config/buffed/config.json"
DEFAULT_CONFIG :: Config{
    font_size  = 28,
    tab_size   = 4,
    use_spaces = true,
}

config_load :: proc() -> (Config, bool) {
    arena: virtual.Arena
    if err := virtual.arena_init_growing(&arena); err != nil {
        fmt.println("Error crearing arena allocator")
        return DEFAULT_CONFIG, false
    }
    defer virtual.arena_destroy(&arena)
    arena_allocator := virtual.arena_allocator(&arena)

    home_dir := os.get_env("HOME", arena_allocator)

    path, err := filepath.join(
        { home_dir, BASE_CONFIG_PATH },
        arena_allocator
    )
    
    if err != nil {
        return DEFAULT_CONFIG, false
    }

    data, ok := os.read_entire_file(path, arena_allocator)

    if !ok {
        fmt.println("Base configuration file is missing or couldn't be opened")
        return DEFAULT_CONFIG, false
    }

    config: Config
    if err := json.unmarshal(data, &config); err != nil {
        fmt.println("Failed to parse JSON:", err)
        return DEFAULT_CONFIG, false
    }

    if config.font_size == 0 do config.font_size = DEFAULT_CONFIG.font_size
    if config.tab_size  == 0 do config.tab_size  = DEFAULT_CONFIG.tab_size

    return config, true
}

config_destroy :: proc(conf: ^Config) {
    delete(conf.font_path)
    delete(conf.theme_path)
    delete(conf.keybindings)
    delete(conf.langs_dir)
    for key, val in conf.lsp_servers {
        delete(key)
        delete(val)
    }
    delete(conf.lsp_servers)
}
