package tinyfiledialogs

import "core:c"

foreign import lib "libtinyfiledialogs.a"

@(default_calling_convention = "c")
foreign lib {
    tinyfd_openFileDialog :: proc(
        title:              cstring,
        default_path:       cstring,
        num_filters:        c.int,
        filter_patterns:    [^]cstring,
        filter_description: cstring,
        allow_multi_select: c.int,
    ) -> cstring ---

    tinyfd_saveFileDialog :: proc(
        title:              cstring,
        default_path:       cstring,
        num_filters:        c.int,
        filter_patterns:    [^]cstring,
        filter_description: cstring,
    ) -> cstring ---
}
