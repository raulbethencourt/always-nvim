#!/bin/bash
# shellcheck shell=bash
# shellcheck disable=SC1091,SC2016

set -e

# install.sh — Install always-nvim to ~/.local/share/always-nvim with symlink in /usr/local/bin

# ── Resolve script directory (symlink-safe) ──────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# ── Source shell library for echo_error, or define fallback ──────────────────
if [ -f "$SCRIPT_DIR/lib/.toolbox" ]; then
  source "$SCRIPT_DIR/lib/.toolbox"
else
  echo_error() { printf '%s\n' "ERROR: $*" >&2; }
  GREENF="" YELLOWF="" CYANF="" BLUEF="" RESET=""
fi

# ── Verify running from repo root ───────────────────────────────────────────
[ -f "$SCRIPT_DIR/always-nvim" ] || {
  echo_error "always-nvim not found in $SCRIPT_DIR. Run install.sh from the repository root."
  exit 1
}

# ── Configuration ────────────────────────────────────────────────────────────
INSTALL_DIR="${INSTALL_DIR:-$HOME/.local/share/always-nvim}"
SYMLINK_DIR="${SYMLINK_DIR:-/usr/local/bin}"
CONFIG_DIR="$HOME/.config/always-nvim"

# ── Install files to application directory ──────────────────────────────────
mkdir -p "$INSTALL_DIR/backends" "$INSTALL_DIR/lib"

cp "$SCRIPT_DIR/always-nvim" "$INSTALL_DIR/always-nvim"
chmod +x "$INSTALL_DIR/always-nvim"
printf '%s\n' "  ${GREENF}Installed:${RESET} always-nvim -> $INSTALL_DIR/always-nvim"

cp "$SCRIPT_DIR/backends/x11.sh" "$INSTALL_DIR/backends/x11.sh"
cp "$SCRIPT_DIR/backends/wayland.sh" "$INSTALL_DIR/backends/wayland.sh"
printf '%s\n' "  ${GREENF}Installed:${RESET} backends/x11.sh -> $INSTALL_DIR/backends/x11.sh"
printf '%s\n' "  ${GREENF}Installed:${RESET} backends/wayland.sh -> $INSTALL_DIR/backends/wayland.sh"

cp -a "$SCRIPT_DIR/lib/." "$INSTALL_DIR/lib/"
printf '%s\n' "  ${GREENF}Installed:${RESET} lib/ -> $INSTALL_DIR/lib/"

# ── Create symlink in system PATH ───────────────────────────────────────────
if [ -w "$SYMLINK_DIR" ]; then
  ln -sf "$INSTALL_DIR/always-nvim" "$SYMLINK_DIR/always-nvim"
  printf '%s\n' "  ${GREENF}Symlink:${RESET} $SYMLINK_DIR/always-nvim -> $INSTALL_DIR/always-nvim"
else
  if sudo ln -sf "$INSTALL_DIR/always-nvim" "$SYMLINK_DIR/always-nvim"; then
    printf '%s\n' "  ${GREENF}Symlink:${RESET} $SYMLINK_DIR/always-nvim -> $INSTALL_DIR/always-nvim"
  else
    printf '%s\n' "  ${YELLOWF}⚠ Could not create symlink in $SYMLINK_DIR (sudo failed)${RESET}"
    printf '%s\n' "  ${YELLOWF}Create it manually:${RESET} sudo ln -sf '$INSTALL_DIR/always-nvim' '$SYMLINK_DIR/always-nvim'"
  fi
fi

# ── Detect old install location and warn ────────────────────────────────────
[ -f "$HOME/.local/bin/always-nvim" ] && [ ! -L "$HOME/.local/bin/always-nvim" ] && {
  printf '\n%s\n' "  ${YELLOWF}⚠ Old installation detected at ~/.local/bin/${RESET}"
  printf '%s\n' "  You can remove old files:"
  printf '%s\n' "    rm ~/.local/bin/always-nvim"
  printf '%s\n' "    rm -rf ~/.local/bin/backends"
  printf '%s\n' "    rm -rf ~/.local/bin/lib"
}

# ── Config directory and example config ─────────────────────────────────────
mkdir -p "$CONFIG_DIR"

if [ -f "$CONFIG_DIR/config" ]; then
  printf '%s\n' "  ${YELLOWF}Existing config preserved:${RESET} $CONFIG_DIR/config"
else
  cat >"$CONFIG_DIR/config" <<'CONFIGEOF'
# always-nvim configuration
# Uncomment and edit variables to override defaults

# Terminal command (must accept -e flag for command execution)
# NA_TERMINAL_CMD="alacritty --class always-nvim --title always-nvim -e"

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
  printf '%s\n' "  ${GREENF}Created:${RESET} $CONFIG_DIR/config"
fi

# ── Post-install WM instructions ────────────────────────────────────────────
printf '\n%s\n' "${CYANF}=== Window Manager Configuration ===${RESET}"

printf '\n%s\n' "${BLUEF}--- i3 (~/.config/i3/config) ---${RESET}"
printf '%s\n' '  # Hotkey'
printf '%s\n' '  bindsym $mod+e exec "always-nvim"'
printf '%s\n' ''
printf '%s\n' '  # Floating window rule'
printf '%s\n' '  for_window [class="always-nvim"] floating enable, sticky enable, resize set 1200 800, move position center'

printf '\n%s\n' "${BLUEF}--- Hyprland (~/.config/hypr/hyprland.conf) ---${RESET}"
printf '%s\n' '  # Hotkey'
printf '%s\n' '  bind = $mainMod, E, exec, always-nvim'
printf '%s\n' ''
printf '%s\n' '  # Floating window rules'
printf '%s\n' '  windowrulev2 = float,title:^(always-nvim)$'
printf '%s\n' '  windowrulev2 = size 800 600,title:^(always-nvim)$'
printf '%s\n' '  windowrulev2 = center,title:^(always-nvim)$'
printf '%s\n' '  windowrulev2 = pin,title:^(always-nvim)$'

printf '\n%s\n' "${CYANF}=== PATH Check ===${RESET}"
# Force path rehash so command -v sees the new binary
hash -r 2>/dev/null || true

if command -v always-nvim >/dev/null 2>&1; then
  printf '%s\n' "  ${GREENF}✓${RESET} always-nvim is in your PATH"
else
  printf '%s\n' "  ${YELLOWF}⚠${RESET} always-nvim is NOT in your PATH"
  printf '%s\n' "  The symlink at $SYMLINK_DIR/always-nvim should make it available."
  printf '%s\n' "  If not, ensure $SYMLINK_DIR is in your PATH."
fi

printf '\n%s\n' "${GREENF}Installation complete!${RESET}"
