# Personal Agents Drawer

Your personal agents, one keystroke away on [Omarchy](https://omarchy.org).

A drawer slides in from the right edge of the screen, over whatever you are
doing, without retiling your windows. Inside are the web apps of your
personal agents, already loaded and signed in, restyled to look like the rest
of your Omarchy desktop: your theme's colors, your monospace font, square
corners. Switch themes and the drawer follows.

| Agent | Web app | Theme | Status |
| --- | --- | --- | --- |
| [Claude Duet](https://claude.ai/duet) | `claude.ai/duet` | full | tested |
| [Muse](https://muse.ai) | `muse.ai` | full | tested |
| [ChatGPT Dots](https://openai.com/index/introducing-dots/) | `chatgpt.com/dots` | base skin | **untested** |

> **ChatGPT Dots is untested.** It was added from public information (Dots
> needs a ChatGPT Pro or Business Premium plan) and the author has no
> account: its window opens and docks correctly, but nobody has used it past
> the sign-in page here, and it only gets the base skin. If you use Dots, an
> issue or pull request with what works (and a site theme) is very welcome.

Turn agents on and off from the drawer's home page (**+ Add**), and add your
own in one line (see [Adding an agent](#adding-an-agent)). "Base skin" means
your font, background and square corners; a full theme also maps the site's
own colors.

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
| Agent list | `~/.local/share/agents-drawer/agents.json` |
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
- The extension runs only on the agents' sites (generated from the agent
  list), and only in the drawer's profile. It changes how the pages look; it
  does not read your conversations.
- The native messaging host accepts four fixed commands (`show`, `ensure`,
  `hide`, `close`) for the agents in the list and passes nothing else on.
  Only the drawer's extension may call it.
- The launcher opens agents by id, from the list, never a URL it is handed.
  `agents-drawer build` accepts only plain `https://` addresses.
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
- Agents have to have a web app. Grok Bot, for one, is desktop and iOS only
  for now.

## Adding an agent

Any agent with a web app works. Put it in `~/.config/agents-drawer/agents.json`:

```json
[
  { "id": "gemini", "name": "Gemini", "url": "https://gemini.google.com/app" }
]
```

and run `agents-drawer build`. It shows up on the home page; click it and
sign in. Entries with the id of a shipped agent replace it, and
`{ "id": "dots", "disabled": true }` hides one. Optional fields: `label`
(the short name under the logo), `hosts` (extra domains the app lives on),
`icon` (otherwise the site's own favicon, once it has loaded once) and
`theme`.

`theme` names a CSS file in `extension/sites/` that maps the site's own
design tokens onto the `--om-*` variables in the generated `theme.css`; see
`claude.css` and `muse.css`. Without one an agent gets the base skin. To add
an agent for everyone, add it to `agents.json` in this repo and send a pull
request.

## License

MIT. Not affiliated with Omarchy, Anthropic or Meta. Claude and Muse are
their owners' trademarks; the drawer shows the sites' own icons.
