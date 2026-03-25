package editor

import "core:os"
import "core:strings"
import "core:path/filepath"

// caller owns the resulted string
git_branch_detect :: proc(cwd: string) -> string {
    dir: string
    if cwd == "" {
        dir, _ = os.get_working_directory(context.allocator)
    } else if os.is_dir(cwd) {
        dir = strings.clone(cwd)
    } else {
        dir = filepath.dir(cwd)
    }
    defer delete(dir)

    for {
        head_path, _ := filepath.join({dir, ".git", "HEAD"}, context.allocator)
        defer delete(head_path)

        data, err := os.read_entire_file(head_path, context.allocator)
        if err != nil {
            // Go up one level
            parent := filepath.dir(dir)
            if parent == dir {
                delete(parent)
                break
            }
            delete(dir)
            dir = parent
            continue
        }
        defer delete(data)
        content := string(data)
        // HEAD contains: "ref: refs/heads/main\n"
        prefix := "ref: refs/heads/"
        if strings.has_prefix(content, prefix) {
            branch := strings.trim_right(content[len(prefix):], "\n\r")
            return strings.clone(branch)
        }
        return ""
    }
    return ""
}
