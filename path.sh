#!/usr/bin/env bash
set -eo pipefail

BIN_DIR=$HOME/.local/bin
FILE=$0
UPDATE_URL="https://raw.githubusercontent.com/sophb-ccjt/path-cli/main/path.sh"
CHANGELOG_URL="https://raw.githubusercontent.com/sophb-ccjt/path-cli/main/CHANGELOG.md"
VERSION=0.1.2

force=0
verbose=0
oblige=0
lenient=0
goeasy=0
flaghelp() {
    echo "--force (-f)         : overwrite files without confirmation";
    echo "--verbose (-v)       : enable verbose output";
    echo "--oblige (-o)        : create directory if it doesn't exist";
    echo "--lenient (-l)       : create stub files for missing commands";
    echo "--goeasy (-g)        : equivalent to -lof (--lenient --oblige --force)";
}
cmdhelp() {
    echo "help                 : Displays a list of valid commands and flags"
    echo "flags                : Displays a list of valid flags"
    echo "commands (or cmds)   : Displays a list of valid commands"
    echo "update               : Updates path to the latest version"
    echo "changelog            : Displays the changelog for the latest version"
    echo "list                 : Lists all commands in the user's PATH"
    echo "add <file>           : Adds a file to the user's PATH"
    echo "put <file>           : Copies a file to the user's PATH"
    echo "grab <command>       : Grabs a command from PATH and copies it locally"
    echo "take <command>       : Takes a command from the user's PATH"
    echo "remove <command>     : Removes a command from the user's PATH"
}
help() {
    echo "  Usage:"
    echo "path [flags] <command> [args]"
    echo
    echo "  Commands:"
    cmdhelp
    echo
    echo "  Flags:"
    flaghelp
}

# ==== Flag Parsing (stackable) ====
while [[ "$1" == -* ]]; do
    case "$1" in
        --force)   force=1; shift ;;
        --verbose) verbose=1; shift ;;
        --oblige)  oblige=1; shift ;;
        --lenient) lenient=1; shift ;;
        --goeasy)  goeasy=1; shift ;;
        -*)
            flags="${1#-}"
            for (( i=0; i<${#flags}; i++ )); do
                case "${flags:$i:1}" in
                    f) force=1 ;;
                    v) verbose=1 ;;
                    o) oblige=1 ;;
                    l) lenient=1 ;;
                    g) goeasy=1 ;;
                    *)
                        echo "Unknown flag: -${flags:$i:1}"
                        exit 1
                        ;;
                esac
            done
            shift
            ;;
    esac
done

# Normalize goeasy
if [[ $goeasy -eq 1 ]]; then
    lenient=1
    oblige=1
    force=1
fi

cmd="$1"
arg="$2"

# ==== Helpers ====
log() {
    if [[ $verbose -eq 1 ]]; then
        echo "$1"
    fi
}

warn() {
    echo "Warning: $1" >&2
}

confirm() {
    [[ $force -eq 1 || $oblige -eq 1 ]] && return 0
    read -rp "$1 [y/N]: " ans
    [[ "$ans" == "y" || "$ans" == "Y" ]]
}

ensure_user_bin() {
    if [[ ! -d "$BIN_DIR" ]]; then
        if [[ $oblige -eq 1 ]]; then
            mkdir -p "$BIN_DIR"
            log "Created $BIN_DIR"
        else
            echo "$BIN_DIR does not exist (use -o to create)"
            exit 1
        fi
    fi
}

resolve_path() {
    command -v "$1" 2>/dev/null || true
}

is_user_bin() {
    case "$1" in
        "$BIN_DIR"/*) return 0 ;;
        *) return 1 ;;
    esac
}

create_lenient_stub() {
    target="$1"

    if [[ -e "$target" && $force -ne 1 ]]; then
        echo "File exists (use -f to overwrite)"
        exit 1
    fi

    warn "Hey, it seems like $arg isn't a command in PATH. We're just creating a stub for now, since you're using lenient mode. Be more careful next time!"

    cat > "$target" <<'EOF'
#!/usr/bin/env bash

# Oops!
# It looks like that file doesn't exist in PATH.
# If you're seeing this, you were either using the "lenient" (--lenient or -l) flag.
# Be more careful next time!
EOF

    chmod +x "$target"
    log "Created lenient stub: $target"
}

ensure_user_bin

# ==== Commands ====
case "$cmd" in
help|"") help ;;
commands|cmds) cmdhelp ;;
flags) flaghelp ;;

list)
    echo "Commands in PATH:"
    echo
    ls "$BIN_DIR"
    ;;

update)
    tmpdir="$(mktemp -d)"
    tmp="$tmpdir/path"

    echo "Downloading latest version..."

    if command -v curl >/dev/null 2>&1; then
        curl -fsSL "$UPDATE_URL" -o "$tmp"
    elif command -v wget >/dev/null 2>&1; then
        wget -qO "$tmp" "$UPDATE_URL"
    else
        echo "curl or wget required"
        exit 1
    fi

    chmod +x "$tmp"

    mv -f "$tmp" "$FILE"

    echo "Updated 'path' successfully."
    ;;

changelog)
    if command -v curl >/dev/null 2>&1; then
        response=$(curl -s "$CHANGELOG_URL")
    elif command -v wget >/dev/null 2>&1; then
        response=$(wget "$CHANGELOG_URL")
    else
        echo "curl or wget required"
        exit 1
    fi

    echo "$response"
    ;;

about)
    echo "path version $VERSION"
    echo "A simple CLI tool to manage your PATH"
    echo "Source code: https://github.com/sophb-ccjt/path-cli"
    ;;

add)
    [[ -z "$arg" ]] && { echo "Missing argument"; exit 1; }
    [[ ! -f "$arg" ]] && { echo "File not found"; exit 1; }
    chmod +x "$arg"
    log "Moving $arg → $BIN_DIR/"
    mv ${force:+-f} "$arg" "$BIN_DIR/"
    echo "Moved $arg to $BIN_DIR/ (use 'path put' to copy instead of moving)"
    ;;

put)
    [[ -z "$arg" ]] && { echo "Missing argument"; exit 1; }
    [[ ! -f "$arg" ]] && { echo "File not found"; exit 1; }
    chmod +x "$arg"
    cp ${force:+-f} "$arg" "$BIN_DIR/"
    echo "Copied $arg to $BIN_DIR/ (use 'path add' to move instead of copying)"
    ;;

grab)
    [[ -z "$arg" ]] && { echo "Missing argument"; exit 1; }
    src="$(resolve_path "$arg")"

    if [[ -z "$src" ]]; then
        [[ $lenient -eq 1 ]] && { create_lenient_stub "./$arg"; exit 0; }
        echo "Not found"
        exit 1
    fi

    is_user_bin "$src" || { echo "Refusing system binary"; exit 1; }

    log "Copying $src → ./"
    cp ${force:+-f} "$src" "./$(basename "$src")"
    echo "Copied $src to ./ (use 'path take' to move instead of copying)"
    ;;

take)
    [[ -z "$arg" ]] && { echo "Missing argument"; exit 1; }
    src="$(resolve_path "$arg")"

    if [[ -z "$src" ]]; then
        [[ $lenient -eq 1 ]] && { create_lenient_stub "./$arg"; exit 0; }
        echo "Not found"
        exit 1
    fi

    is_user_bin "$src" || { echo "Refusing system binary"; exit 1; }

    log "Moving $src → ./"
    mv ${force:+-f} "$src" "./$(basename "$src")"
    echo "Moved $src to ./ (use 'path grab' to copy instead of moving)"
    ;;

remove)
    [[ -z "$arg" ]] && { echo "Missing argument"; exit 1; }
    src="$(resolve_path "$arg")"

    if [[ -z "$src" ]]; then
        [[ $lenient -eq 1 ]] && {
            warn "Hey, it seems like $arg isn't a command in PATH. Be more careful next time!"
            exit 0;
        }
        echo "Not found"
        exit 1
    fi

    is_user_bin "$src" || { echo "Refusing system binary"; exit 1; }

    if confirm "Remove $(basename "$src") from PATH?"; then
        log "Removing $src"
        rm ${force:+-f} "$src"
    else
        echo "Cancelled"
        exit 1
    fi
    ;;

*)
    echo "Unknown command: $cmd"
    echo "Use 'path cmds' to see available commands"
    echo "Use 'path flags' to see available flags"
    exit 1
    ;;

esac
local_hash=$(sha256sum "$FILE" | awk '{print $1}')
remote_hash=$(curl -fsSL "$UPDATE_URL" | sha256sum | awk '{print $1}')

if [[ "$local_hash" == "$remote_hash" ]]; then
    log "Up to date."
else
    echo "Hey friend, it seems that path is outdated. Run 'path update' to fix that."
fi
