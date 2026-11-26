#!/bin/bash
# Removes what install.sh set up. The drawer's browser profile (your agent
# sign-ins) is kept unless you pass --purge.
set -euo pipefail

DATA="${XDG_DATA_HOME:-$HOME/.local/share}/agents-drawer"
BIN="$HOME/.local/bin"
HYPR="${XDG_CONFIG_HOME:-$HOME/.config}/hypr"
HOOKS="${XDG_CONFIG_HOME:-$HOME/.config}/omarchy/hooks"

[[ -x $BIN/agents-drawer ]] && "$BIN/agents-drawer" stop || true

if [[ -f $HYPR/hyprland.lua ]] && grep -qF 'require("hypr.agents-drawer")' "$HYPR/hyprland.lua"; then
  cp "$HYPR/hyprland.lua" "$HYPR/hyprland.lua.bak.$(date +%s)"
  sed -i -e '/^-- Personal Agents Drawer (remove with its uninstall.sh)$/d' \
    -e '/^require("hypr.agents-drawer")$/d' "$HYPR/hyprland.lua"
fi
rm -f "$HYPR/agents-drawer.lua"
command -v hyprctl >/dev/null && hyprctl reload >/dev/null || true

rm -f "$HOOKS/theme-set.d/agents-drawer-theme" "$HOOKS/font-set.d/agents-drawer-theme"
rm -f "$BIN/agents-drawer"
rm -rf "$DATA/extension" "$DATA/host.py"

if [[ ${1:-} == --purge ]]; then
  rm -rf "$DATA"
  echo "Removed Personal Agents Drawer and its browser profile."
else
  rmdir "$DATA" 2>/dev/null || true
  echo "Removed Personal Agents Drawer. Your agent sign-ins are kept in $DATA/profile (uninstall.sh --purge removes them)."
fi
echo "Remove the bar button with: omarchy plugin remove io.github.caiomsantos95.personal-agents-drawer"
