#!/usr/bin/env bash
set -euo pipefail

# Miku theme installer for kitty + fish.
# Follows the same idea as fastfetch-theme: back up what is going to be
# overwritten into ~/.config/<program>/backups/backup_DATE/ and then copy.
#
# Two modes: kitty + fish (keeps the user's own fastfetch, if any), or
# kitty + fish + the Miku fastfetch theme.
#
# Supports apt (Debian/Ubuntu), pacman (Arch), dnf (Fedora/RHEL),
# zypper (openSUSE) and brew (macOS/Linuxbrew).

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
TIMESTAMP="$(date +%Y%m%d_%H%M%S)"
FONT_FAMILY="CaskaydiaCove Nerd Font Mono"
FONT_URL="https://github.com/ryanoasis/nerd-fonts/releases/latest/download/CascadiaCode.zip"

ASSUME_YES=0
WITH_FASTFETCH=0

usage() {
    cat <<'EOF'
Usage: ./install.sh [options]

Options:
  -y, --yes          answer yes to every prompt (non-interactive)
      --with-fastfetch
                     also install the fastfetch theme (skips the menu)
  -h, --help         show this help

The script installs kitty, fish and the Nerd Font if they are missing,
backs up the files it overwrites, and copies the theme. fastfetch is optional.
EOF
}

for arg in "$@"; do
    case "$arg" in
        -y|--yes) ASSUME_YES=1 ;;
        --with-fastfetch) WITH_FASTFETCH=1 ;;
        -h|--help) usage; exit 0 ;;
        *) echo "Unknown option: $arg"; usage; exit 1 ;;
    esac
done

confirm() {
    [ "$ASSUME_YES" -eq 1 ] && return 0
    local answer
    read -r -p "$1 [y/N] " answer || return 1
    [[ "$answer" =~ ^[Yy]$ ]]
}

choose_mode() {
    if [ "$WITH_FASTFETCH" -eq 1 ]; then
        MODE="full"
        return
    fi
    if [ "$ASSUME_YES" -eq 1 ]; then
        MODE="minimal"
        return
    fi

    echo "What do you want to install?"
    echo "  1) kitty + fish (keep your own fastfetch, if installed)"
    echo "  2) kitty + fish + Miku fastfetch theme"
    echo
    local choice
    read -r -p "Choose [1/2] (default 1): " choice || choice=""
    case "$choice" in
        2) MODE="full" ;;
        *) MODE="minimal" ;;
    esac
}

choose_mode

# ---------------------------------------------------------------- distro ---

detect_pm() {
    for candidate in apt-get pacman dnf zypper brew; do
        if command -v "$candidate" >/dev/null 2>&1; then
            echo "$candidate"
            return 0
        fi
    done
    return 1
}

PM="$(detect_pm || true)"

DISTRO="unknown"
if [ -r /etc/os-release ]; then
    . /etc/os-release
    DISTRO="${PRETTY_NAME:-${NAME:-unknown}}"
fi

SUDO=""
if [ "$(id -u)" -ne 0 ]; then
    SUDO="sudo"
fi

install_pkg() {
    local pkg="$1"
    case "$PM" in
        apt-get) $SUDO apt-get update && $SUDO apt-get install -y "$pkg" ;;
        pacman)  $SUDO pacman -S --needed --noconfirm "$pkg" ;;
        dnf)     $SUDO dnf install -y "$pkg" ;;
        zypper)  $SUDO zypper --non-interactive --auto-agree-with-licenses install "$pkg" ;;
        brew)
            if [ "$pkg" = "kitty" ]; then
                brew install --cask kitty
            else
                brew install "$pkg"
            fi
            ;;
        *) return 1 ;;
    esac
}

echo "System: $DISTRO"
if [ -n "$PM" ]; then
    echo "Package manager: $PM"
else
    echo "Package manager: not detected (automatic installs disabled)"
fi

# --------------------------------------------------------------- helpers ---

require_cmd() {
    local cmd="$1" pkg="${2:-$1}" required="${3:-yes}"

    if command -v "$cmd" >/dev/null 2>&1; then
        return 0
    fi

    echo
    echo "==> '$cmd' is not installed."
    if [ -z "$PM" ]; then
        echo "No supported package manager found."
        echo "Install '$pkg' manually and run this script again."
        [ "$required" = "yes" ] && exit 1
        return 1
    fi

    if confirm "Install '$pkg' with $PM?"; then
        if install_pkg "$pkg"; then
            return 0
        fi
        echo "Automatic installation of '$pkg' failed."
    fi

    if [ "$required" = "yes" ]; then
        echo "Cannot continue without '$cmd'."
        exit 1
    fi
    return 1
}

font_installed() {
    command -v fc-list >/dev/null 2>&1 || return 1
    local families
    families="$(fc-list : family 2>/dev/null || true)"
    case "$families" in
        *"$FONT_FAMILY"*) return 0 ;;
        *) return 1 ;;
    esac
}

install_font_zip() {
    local dest="${XDG_DATA_HOME:-$HOME/.local/share}/fonts/CaskaydiaCoveNerdFont"
    local tmp
    tmp="$(mktemp -d)"

    echo "Downloading Nerd Font (~55 MB)..."
    if command -v curl >/dev/null 2>&1; then
        curl -fL --progress-bar --retry 2 -o "$tmp/font.zip" "$FONT_URL" || { rm -rf "$tmp"; return 1; }
    elif command -v wget >/dev/null 2>&1; then
        wget -qO "$tmp/font.zip" "$FONT_URL" || { rm -rf "$tmp"; return 1; }
    else
        echo "curl or wget is required to download the font."
        rm -rf "$tmp"
        return 1
    fi

    mkdir -p "$dest"
    if command -v unzip >/dev/null 2>&1; then
        unzip -qo "$tmp/font.zip" 'CaskaydiaCoveNerdFontMono-*.ttf' -d "$dest" || { rm -rf "$tmp"; return 1; }
    elif command -v python3 >/dev/null 2>&1; then
        python3 - "$tmp/font.zip" "$dest" <<'PY' || { rm -rf "$tmp"; return 1; }
import sys, zipfile
with zipfile.ZipFile(sys.argv[1]) as z:
    for name in z.namelist():
        if name.startswith("CaskaydiaCoveNerdFontMono-") and name.endswith(".ttf"):
            z.extract(name, sys.argv[2])
PY
    else
        echo "unzip or python3 is required to extract the font."
        rm -rf "$tmp"
        return 1
    fi

    if command -v fc-cache >/dev/null 2>&1; then
        fc-cache -f >/dev/null 2>&1 || true
    fi
    rm -rf "$tmp"
    return 0
}

check_font() {
    if font_installed; then
        return 0
    fi

    echo
    echo "==> Font '$FONT_FAMILY' not found."

    if [ "$PM" = "brew" ]; then
        if confirm "Install font-caskaydia-cove-nerd-font with Homebrew?"; then
            if brew install --cask font-caskaydia-cove-nerd-font; then
                return 0
            fi
        fi
    else
        if confirm "Download it from Nerd Fonts (~55 MB)?"; then
            if install_font_zip; then
                echo "Font installed in ${XDG_DATA_HOME:-$HOME/.local/share}/fonts"
                return 0
            fi
        fi
    fi

    echo "Warning: kitty will fall back to another font."
}

# ------------------------------------------------------------- install ---

install_component() {
    local name="$1"
    local src="$ROOT/$name"
    local target="$CONFIG_HOME/$name"

    echo
    echo "==> $name"

    if [ ! -d "$src" ] || [ -z "$(ls -A "$src" 2>/dev/null)" ]; then
        echo "Error: the '$name' folder is missing or empty."
        echo "Nothing has been modified."
        exit 1
    fi

    local backup_dir="$target/backups/backup_$TIMESTAMP"
    local suffix=1
    while [ -e "$backup_dir" ]; do
        backup_dir="$target/backups/backup_${TIMESTAMP}_$suffix"
        suffix=$((suffix + 1))
    done
    local has_backup=0

    while IFS= read -r -d '' file; do
        local rel="${file#"$src"/}"
        if [ -e "$target/$rel" ]; then
            mkdir -p "$backup_dir/$(dirname "$rel")"
            mv "$target/$rel" "$backup_dir/$rel"
            has_backup=1
        fi
    done < <(find "$src" -type f -print0)

    mkdir -p "$target"
    cp -r "$src"/. "$target"/

    if [ "$has_backup" -eq 1 ]; then
        echo "Previous files backed up to:"
        echo "  $backup_dir"
    else
        echo "No previous configuration found."
    fi
    echo "Installed to: $target"
}

# The repo ships /usr/bin/fish, which is wrong on macOS/Homebrew and NixOS.
# Point kitty at the fish binary that is actually installed here.
point_kitty_to_fish() {
    local conf="$CONFIG_HOME/kitty/kitty.conf"
    local fish_path tmp

    fish_path="$(command -v fish || true)"
    [ -n "$fish_path" ] || return 0
    [ -f "$conf" ] || return 0
    grep -q '^shell ' "$conf" || return 0

    tmp="$(mktemp)"
    sed "s|^shell .*|shell $fish_path|" "$conf" > "$tmp"
    cat "$tmp" > "$conf"
    rm -f "$tmp"
    echo "kitty shell set to: $fish_path"
}

# The shipped config points at ~/.config/fastfetch/logo.txt. With
# XDG_CONFIG_HOME set, the installer copies the logo somewhere else, so rewrite
# the path to wherever it was actually installed.
point_fastfetch_to_logo() {
    local conf="$CONFIG_HOME/fastfetch/config.jsonc"
    local logo="$CONFIG_HOME/fastfetch/logo.txt"
    local tmp

    [ -f "$conf" ] || return 0
    [ -f "$logo" ] || return 0

    tmp="$(mktemp)"
    sed "s|\"source\": \"[^\"]*logo.txt\"|\"source\": \"$logo\"|" "$conf" > "$tmp"
    cat "$tmp" > "$conf"
    rm -f "$tmp"
    echo "fastfetch logo set to: $logo"
}

echo
echo "Checking dependencies..."
require_cmd kitty
require_cmd fish
check_font

if [ "$MODE" = "full" ]; then
    # Full mode explicitly asks for fastfetch, so install it without a prompt.
    if ! command -v fastfetch >/dev/null 2>&1; then
        echo
        echo "==> 'fastfetch' is not installed."
        if [ -n "$PM" ]; then
            echo "Installing 'fastfetch' with $PM..."
            if ! install_pkg fastfetch; then
                echo "Warning: automatic installation failed; the welcome block will be skipped."
            fi
        else
            echo "No supported package manager found; install 'fastfetch' manually."
        fi
    fi
else
    echo
    if command -v fastfetch >/dev/null 2>&1; then
        if [ -f "$CONFIG_HOME/fastfetch/config.jsonc" ]; then
            echo "Existing fastfetch detected: your own configuration will be kept and used."
        else
            echo "Existing fastfetch detected: it will run with its default settings."
        fi
    else
        echo "fastfetch is not installed; the welcome block will be skipped."
        echo "Run with option 2 (--with-fastfetch) to install the Miku fastfetch theme."
    fi
fi

install_component kitty
point_kitty_to_fish
install_component fish

if [ "$MODE" = "full" ]; then
    install_component fastfetch
    point_fastfetch_to_logo
fi

echo
echo "Done."
echo "  kitty: open a new window or press alt+f5 to reload."
echo "  fish:  open a new terminal or run 'exec fish'."
if [ "$MODE" = "full" ]; then
    echo "  fastfetch: it will appear the next time you open a terminal."
else
    echo "  fastfetch: left untouched; your existing setup is used if installed."
fi
