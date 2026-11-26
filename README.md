# Personal Agents Drawer

Your personal agents, one keystroke away on [Omarchy](https://omarchy.org).

A drawer slides in from the right edge of the screen, over whatever you are
doing, without retiling your windows. Inside are the web apps of your
personal agents, [Claude Duet](https://claude.ai/duet) and
[Muse](https://muse.ai), already loaded and signed in, restyled to look like
the rest of your Omarchy desktop: your theme's colors, your monospace font,
square corners. Switch themes and the drawer follows.

![Personal Agents Drawer](preview.png)

- **`Super + D`** toggles the drawer. So does the `◆` button in the bar.
- **Rest the pointer on the right edge** of a screen for half a second to open it.
- **Click outside** the drawer to close it.
- **Agent logos** across the top switch agents; **`Alt + 1…9`** does too,
  **`Alt + 0`** opens the home page where you turn agents on and off.
- Agents are **pre-rendered**: each runs in a hidden window from login, so
  opening the drawer or switching agents never reloads a page.

## Install

You need Omarchy with its Lua Hyprland config (tested on Omarchy 4.5,
Hyprland 0.56) and Chromium.

```sh
omarchy plugin add https://github.com/caiomsantos95/omarchy-personal-agents-drawer.git --enable
~/.config/omarchy/plugins/io.github.caiomsantos95.personal-agents-drawer/install.sh
```

The first command installs the bar button. The second sets up the drawer
itself; it is a plain shell script, so read it first. It installs:

| What | Where |
| --- | --- |
| Launcher | `~/.local/bin/agents-drawer` |
| Chromium extension (home page, agent tabs, theme cover) | `~/.local/share/agents-drawer/extension/` |
| Native messaging host | `~/.local/share/agents-drawer/host.py` |
| Hyprland module, required from `hyprland.lua` (backed up first) | `~/.config/hypr/agents-drawer.lua` |
| Theme and font hooks | `~/.config/omarchy/hooks/{theme-set,font-set}.d/agents-drawer-theme` |

Then press `Super + D`, click an agent's logo and sign in once. The drawer
has its own browser profile (`~/.local/share/agents-drawer/profile/`), so it
stays signed in and never touches your main browser.

Re-run `install.sh` after updating the plugin. To remove everything:

```sh
~/.config/omarchy/plugins/io.github.caiomsantos95.personal-agents-drawer/uninstall.sh   # --purge also deletes the sign-ins
omarchy plugin remove io.github.caiomsantos95.personal-agents-drawer
```

## How it works

- **Windows.** Each agent is a Chromium `--app` window in the drawer's own
  profile. The Hyprland module floats them all in the `special:agents`
  workspace, stacked into one panel on the right: a header window with the
  agent logos on top, the current agent's window under it. A special
  workspace shows over any workspace and dims it, so nothing is retiled.
- **Header and home page.** A small Chromium extension draws the header and
  the home page, and keeps which agents are on. Clicking a logo goes through
  a native messaging host to Hyprland, which raises that agent's window.
- **Theme.** `agents-drawer theme` turns the current theme's `colors.toml`
  and monospace font into CSS variables. The extension injects them into each
  agent's page with a small per-site file (`extension/sites/`) that maps the
  site's own design tokens onto them. Omarchy's theme and font hooks rerun it,
  and the pages pick the change up within a few seconds.
- **Edge and clicks.** A 75 ms timer inside Hyprland watches for the pointer
  resting on a right screen edge, and a pass-through left-click binding closes
  the drawer when the click lands outside it. Focus follows the mouse in
  Omarchy, so a click, not a focus change, is what closes it.

## Security and privacy

Omarchy plugins run unsandboxed, so here is everything this one does:

- It only talks to the agents' own sites. No analytics, no other network
  access, nothing leaves your machine that the sites would not get anyway.
- The extension runs only on `claude.ai` and `muse.ai`, and only in the
  drawer's profile. It changes how the pages look; it does not read your
  conversations.
- The native messaging host accepts four fixed commands (`show`, `ensure`,
  `hide`, `close`) for three fixed agents and passes nothing else on. Only
  the drawer's extension may call it.
- The launcher opens only `https://claude.ai/…` and `https://muse.ai/…` URLs.
- `install.sh` edits one file outside its own folders: it appends one
  `require` line to `~/.config/hypr/hyprland.lua`, after making a backup.
  `uninstall.sh` removes it.
- Nothing needs root.
- `AGENTS_DRAWER_DEBUG=1 agents-drawer start` opens Chromium's DevTools port
  on localhost for working on site themes. While that is on, any program on
  your machine can drive the signed-in drawer browser, so leave it off.

## Limitations

- The site themes map each site's CSS variables. When a site changes its
  design system, parts of the theme can fall back to the site's own colors
  until `extension/sites/` is updated.
- The drawer recognizes its windows by Chromium's app ids for these exact
  URLs. If you also made a web app for `https://claude.ai/duet` or
  `https://muse.ai/` in your main Chromium profile, it would land in the
  drawer too.
- Chromium only.

## Adding an agent

Add it to `extension/chats.js`, the URL to `APPS` in
`hypr/agents-drawer.lua`, its host to `extension/manifest.json`,
`host/agents-drawer-host.py` and the `app` case in `bin/agents-drawer`, and
write `extension/sites/<name>.css` mapping its design tokens onto the
`--om-*` variables in the generated `theme.css`.

## License

MIT. Not affiliated with Omarchy, Anthropic or Meta. Claude and Muse are
their owners' trademarks; the drawer shows the sites' own icons.
