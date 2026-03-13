#!/usr/bin/env sh
set -e

REPO="https://github.com/bujorelActimel/buffed"
INSTALL_DIR="${HOME}/.local/bin"
BUILD_DIR="${HOME}/.local/share/buffed-src"

RED='\033[0;31m'
GRN='\033[0;32m'
DIM='\033[0;90m'
RST='\033[0m'

info()  { printf "${DIM}=>${RST} %s\n" "$1"; }
ok()    { printf "${GRN}✓${RST}  %s\n" "$1"; }
die()   { printf "${RED}error:${RST} %s\n" "$1" >&2; exit 1; }

# ── checks ──────────────────────────────────────────────────────────────────
command -v odin >/dev/null 2>&1 || die "odin not found. Install from https://odin-lang.org/"
command -v cc   >/dev/null 2>&1 || die "C compiler not found (cc)"
command -v ar   >/dev/null 2>&1 || die "ar not found"
command -v git  >/dev/null 2>&1 || die "git not found"

# ── clone ────────────────────────────────────────────────────────────────────
if [ -d "$BUILD_DIR/.git" ]; then
    info "Updating source in $BUILD_DIR"
    git -C "$BUILD_DIR" pull --ff-only -q
else
    info "Cloning $REPO"
    git clone --depth 1 -q "$REPO" "$BUILD_DIR"
fi

cd "$BUILD_DIR"

# ── tinyfiledialogs ──────────────────────────────────────────────────────────
if [ ! -f vendor/tinyfiledialogs/libtinyfiledialogs.a ]; then
    info "Building tinyfiledialogs"
    cc -c vendor/tinyfiledialogs/tinyfiledialogs.c \
          -o vendor/tinyfiledialogs/tinyfiledialogs.o
    ar rcs vendor/tinyfiledialogs/libtinyfiledialogs.a \
            vendor/tinyfiledialogs/tinyfiledialogs.o
    ok "tinyfiledialogs built"
fi

# ── tree-sitter ──────────────────────────────────────────────────────────────
if [ ! -d vendor/tree-sitter ]; then
    info "Cloning odin-tree-sitter"
    git clone --depth 1 -q \
        https://github.com/laytan/odin-tree-sitter vendor/tree-sitter
fi

if [ ! -f vendor/tree-sitter/lib/libtree-sitter.a ]; then
    info "Installing tree-sitter"
    odin run vendor/tree-sitter/build -- install -q

    for parser in \
        https://github.com/tree-sitter-grammars/tree-sitter-odin \
        https://github.com/tree-sitter/tree-sitter-c \
        https://github.com/tree-sitter/tree-sitter-rust \
        https://github.com/tree-sitter/tree-sitter-go \
        https://github.com/tree-sitter/tree-sitter-python \
        https://github.com/tree-sitter/tree-sitter-json
    do
        info "Installing parser: $(basename $parser)"
        odin run vendor/tree-sitter/build -- install-parser "$parser" -q
    done
    ok "tree-sitter ready"
fi

# ── build ────────────────────────────────────────────────────────────────────
info "Building buffed"
odin build . -out:buffed -o:speed
ok "Build complete"

# ── install ──────────────────────────────────────────────────────────────────
mkdir -p "$INSTALL_DIR"
cp buffed "$INSTALL_DIR/buffed"
ok "Installed to $INSTALL_DIR/buffed"

# ── PATH hint ────────────────────────────────────────────────────────────────
case ":${PATH}:" in
    *":${INSTALL_DIR}:"*) ;;
    *)
        printf "\n${DIM}Add this to your shell profile:${RST}\n"
        printf "  export PATH=\"\$HOME/.local/bin:\$PATH\"\n\n"
        ;;
esac

printf "${GRN}Done!${RST} Run: buffed <file>\n"
