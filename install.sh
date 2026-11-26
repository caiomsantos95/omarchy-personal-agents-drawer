#!/bin/bash
# Installs the desktop half of Personal Agents Drawer. The Omarchy shell
# plugin (the bar button) is installed by `omarchy plugin add`; this sets up
# what it drives:
#
#   ~/.local/bin/agents-drawer                launcher
#   ~/.local/share/agents-drawer/extension/   Chromium extension (home page,
#                                             agent tabs, Omarchy theme cover)
#   ~/.local/share/agents-drawer/host.py      native messaging host
#   ~/.local/share/agents-drawer/agents.json  the agent list (add your own in
#                                             ~/.config/agents-drawer/agents.json)
#   ~/.local/share/agents-drawer/profile/     the drawer's own browser profile
#   ~/.config/hypr/agents-drawer.lua          Hyprland module, required from
#                                             hyprland.lua (backed up first)
#   theme-set and font-set hooks              retint the drawer on changes
#
# Re-running it updates an existing install. uninstall.sh reverses it.
set -euo pipefail

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DATA="${XDG_DATA_HOME:-$HOME/.local/share}/agents-drawer"
BIN="$HOME/.local/bin"
HYPR="${XDG_CONFIG_HOME:-$HOME/.config}/hypr"
REQUIRE='require("hypr.agents-drawer")'

say() { printf '\033[1m%s\033[0m\n' "$*"; }
die() { printf 'install.sh: %s\n' "$*" >&2; exit 1; }

for cmd in chromium hyprctl python3 omarchy uwsm-app; do
  command -v "$cmd" >/dev/null || die "missing $cmd (Personal Agents Drawer needs Omarchy with Chromium)"
done
python3 -c 'import tomllib' 2>/dev/null || die "needs Python 3.11 or newer"
[[ -f $HYPR/hyprland.lua ]] || die "no $HYPR/hyprland.lua; this needs Omarchy's Lua Hyprland config"

say "Installing files"
[[ -x $BIN/agents-drawer ]] && "$BIN/agents-drawer" stop
mkdir -p "$DATA" "$BIN"
rm -rf "$DATA/extension.new"
cp -r "$SRC/browser/extension" "$DATA/extension.new"
rm -rf "$DATA/extension"
mv "$DATA/extension.new" "$DATA/extension"
install -m 755 "$SRC/host/agents-drawer-host.py" "$DATA/host.py"
install -m 644 "$SRC/agents.json" "$DATA/agents.json"
install -m 755 "$SRC/bin/agents-drawer" "$BIN/agents-drawer"
"$BIN/agents-drawer" register
"$BIN/agents-drawer" theme
"$BIN/agents-drawer" build

say "Installing theme hooks"
omarchy hook install theme-set "$SRC/hooks/agents-drawer-theme" >/dev/null
omarchy hook install font-set "$SRC/hooks/agents-drawer-theme" >/dev/null

say "Installing the Hyprland module"
install -m 644 "$SRC/hypr/agents-drawer.lua" "$HYPR/agents-drawer.lua"
if ! grep -qF "$REQUIRE" "$HYPR/hyprland.lua"; then
  cp "$HYPR/hyprland.lua" "$HYPR/hyprland.lua.bak.$(date +%s)"
  printf '\n-- Personal Agents Drawer (remove with its uninstall.sh)\n%s\n' "$REQUIRE" >>"$HYPR/hyprland.lua"
fi
hyprctl reload >/dev/null
errors=$(hyprctl configerrors 2>&1 || true)
if [[ -n ${errors// /} && $errors != "ok" ]]; then
  printf '%s\n' "$errors" >&2
  die "Hyprland reported config errors; run uninstall.sh to back out"
fi

say "Starting the drawer"
"$BIN/agents-drawer" start

cat <<'DONE'

Personal Agents Drawer is ready.

  SUPER + D                 toggle the drawer
  rest on the right edge    open it
  click outside             close it

Open it, pick an agent on the home page and sign in once; it stays signed
in from then on.
DONE
