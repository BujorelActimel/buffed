package editor

import "core:strings"
import tinyfd "../vendor/tinyfiledialogs"

file_picker_open :: proc() -> (path: string, ok: bool) {
    result := tinyfd.tinyfd_openFileDialog("Open File", "", 0, nil, nil, 0)
    if result == nil do return "", false
    return strings.clone(string(result)), true
}
