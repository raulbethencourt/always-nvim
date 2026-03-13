#!/bin/bash
# shellcheck shell=bash
# shellcheck disable=SC1091,SC2016

set -e

# install.sh — Install always-nvim to ~/.local/bin with config and WM instructions

# ── Resolve script directory (symlink-safe) ──────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# ── Source shell library for echo_error, or define fallback ──────────────────
if [ -f "$SCRIPT_DIR/lib/.toolbox" ]; then
  export SHELLTOOLSPATH="$SCRIPT_DIR"
  source "$SCRIPT_DIR/lib/.toolbox"
else
  echo_error() { printf '%s\n' "ERROR: $*" >&2; }
fi

# ── Verify running from repo root ───────────────────────────────────────────
[ -f "$SCRIPT_DIR/always-nvim" ] || {
  echo_error "always-nvim not found in $SCRIPT_DIR. Run install.sh from the repository root."
  exit 1
}

# ── Configuration ────────────────────────────────────────────────────────────
INSTALL_DIR="${INSTALL_DIR:-$HOME/.local/bin}"
CONFIG_DIR="$HOME/.config/always-nvim"

# ── Task 2: Install files ───────────────────────────────────────────────────
mkdir -p "$INSTALL_DIR/backends" "$INSTALL_DIR/lib"

cp "$SCRIPT_DIR/always-nvim" "$INSTALL_DIR/always-nvim"
chmod +x "$INSTALL_DIR/always-nvim"
printf '%s\n' "  Installed: always-nvim -> $INSTALL_DIR/always-nvim"

cp "$SCRIPT_DIR/backends/x11.sh" "$INSTALL_DIR/backends/x11.sh"
cp "$SCRIPT_DIR/backends/wayland.sh" "$INSTALL_DIR/backends/wayland.sh"
printf '%s\n' "  Installed: backends/x11.sh -> $INSTALL_DIR/backends/x11.sh"
printf '%s\n' "  Installed: backends/wayland.sh -> $INSTALL_DIR/backends/wayland.sh"

cp -a "$SCRIPT_DIR/lib/." "$INSTALL_DIR/lib/"
printf '%s\n' "  Installed: lib/ -> $INSTALL_DIR/lib/"

# ── Task 3: Config directory and example config ─────────────────────────────
mkdir -p "$CONFIG_DIR"

if [ -f "$CONFIG_DIR/config" ]; then
  printf '%s\n' "  Existing config preserved: $CONFIG_DIR/config"
else
  cat >"$CONFIG_DIR/config" <<'CONFIGEOF'
# always-nvim configuration
# Uncomment and edit variables to override defaults

# Terminal command (must accept -e flag for command execution)
# NA_TERMINAL_CMD="alacritty --title always-nvim -e"

# Force backend: auto, x11, or wayland
# NA_BACKEND="auto"

# Clear primary selection after each run
# NA_CLEAR_PRIMARY="true"

# Temp file extension / Neovim filetype
# NA_FILETYPE="md"

# Additional args passed to Neovim
# NA_NVIM_ARGS=""

# Seconds to wait after paste before clipboard restore
# NA_PASTE_DELAY="0.2"

# Seconds to wait after refocus before paste
# NA_FOCUS_DELAY="0.1"

# Neovim APPNAME (uses ~/.config/<appname>/ for config, empty = normal config)
# Tip: set to "always-nvim/nvim" for isolated config (~/.config/always-nvim/nvim/)
# NA_NVIM_APPNAME=""
CONFIGEOF
  printf '%s\n' "  Created: $CONFIG_DIR/config"
fi

# ── Task 4: Post-install WM instructions ────────────────────────────────────
printf '\n%s\n' "=== Window Manager Configuration ==="

printf '\n%s\n' "--- i3 (~/.config/i3/config) ---"
printf '%s\n' '  # Hotkey'
printf '%s\n' '  bindsym $mod+e exec always-nvim'
printf '%s\n' ''
printf '%s\n' '  # Floating window rule'
printf '%s\n' '  for_window [title="always-nvim"] floating enable, sticky enable, resize set 800 600, move position center'

printf '\n%s\n' "--- Hyprland (~/.config/hypr/hyprland.conf) ---"
printf '%s\n' '  # Hotkey'
printf '%s\n' '  bind = $mainMod, E, exec, always-nvim'
printf '%s\n' ''
printf '%s\n' '  # Floating window rules'
printf '%s\n' '  windowrulev2 = float,title:^(always-nvim)$'
printf '%s\n' '  windowrulev2 = size 800 600,title:^(always-nvim)$'
printf '%s\n' '  windowrulev2 = center,title:^(always-nvim)$'
printf '%s\n' '  windowrulev2 = pin,title:^(always-nvim)$'

printf '\n%s\n' "=== PATH Check ==="
# Force path rehash so command -v sees the new binary
hash -r 2>/dev/null || true

if command -v always-nvim >/dev/null 2>&1; then
  printf '%s\n' "  ✓ always-nvim is in your PATH"
else
  printf '%s\n' "  ⚠ $INSTALL_DIR is NOT in your PATH. Add it to your shell profile:"
  printf '%s\n' "    export PATH=\"\$HOME/.local/bin:\$PATH\""
fi

printf '\n%s\n' "Installation complete!"
