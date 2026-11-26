import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import qs.Commons

// The always-on half of Personal Agents Drawer, so `omarchy plugin add
// --enable` is the whole install:
//
//   - prepares the drawer's files (bin/agents-drawer prepare) and starts its
//     browser hidden, so agents are pre-rendered from login;
//   - loads the Hyprland module (hypr/agents-drawer.lua) at runtime with
//     `hyprctl eval`, and again after every config reload, instead of editing
//     hyprland.lua;
//   - retints the drawer when the Omarchy theme or font changes;
//   - reapplies your own agent list when ~/.config/agents-drawer/agents.json
//     changes;
//   - when the plugin is disabled or removed, quits the drawer browser and
//     reloads Hyprland, which drops the module.
Item {
  id: root

  readonly property string pluginId: "io.github.caiomsantos95.personal-agents-drawer"
  readonly property string pluginDir: decodeURIComponent(String(Qt.resolvedUrl(".")).replace(/^file:\/\//, "")).replace(/\/$/, "")
  readonly property string launcher: pluginDir + "/bin/agents-drawer"
  readonly property string home: Quickshell.env("HOME")
  readonly property string dataDir: (Quickshell.env("XDG_DATA_HOME") || (home + "/.local/share")) + "/agents-drawer"
  readonly property string configDir: Quickshell.env("XDG_CONFIG_HOME") || (home + "/.config")
  property bool ready: false

  function notify(body) {
    Quickshell.execDetached(["notify-send", "Personal Agents Drawer", body])
  }

  // agents_drawer_root is a JSON string literal, which Lua reads the same way.
  function loadModule() {
    if (!ready) return
    Quickshell.execDetached(["hyprctl", "eval",
      "agents_drawer_root = " + JSON.stringify(pluginDir)
      + "; dofile(agents_drawer_root .. \"/hypr/agents-drawer.lua\")"])
  }

  Process {
    id: prepare
    command: [root.launcher, "prepare"]
    stderr: StdioCollector { id: prepareErrors; waitForEnd: true }
    onExited: function(code) {
      if (code !== 0) {
        root.notify(prepareErrors.text.trim() || "Could not set up the drawer.")
        return
      }
      root.ready = true
      root.loadModule()
      Quickshell.execDetached([root.launcher, "start"])
    }
  }

  Component.onCompleted: prepare.running = true

  // A config reload starts Hyprland's Lua state afresh, without the module.
  Connections {
    target: Hyprland
    function onRawEvent(event) {
      if (event && String(event.name) === "configreloaded") reloadTimer.restart()
    }
  }

  Timer {
    id: reloadTimer
    interval: 300
    onTriggered: root.loadModule()
  }

  // Theme and font changes. The shell has already re-read the theme when
  // these change, so the theme files are in place.
  Connections {
    target: Color
    function onBackgroundChanged() { themeTimer.restart() }
    function onForegroundChanged() { themeTimer.restart() }
  }

  Connections {
    target: Style
    function onFontFamilyChanged() { themeTimer.restart() }
  }

  Timer {
    id: themeTimer
    interval: 500
    onTriggered: if (root.ready) Quickshell.execDetached([root.launcher, "theme"])
  }

  // Your own agents. `build` restarts the drawer browser when it is running.
  FileView {
    path: root.configDir + "/agents-drawer/agents.json"
    watchChanges: true
    printErrors: false
    onFileChanged: buildTimer.restart()
  }

  Timer {
    id: buildTimer
    interval: 500
    onTriggered: if (root.ready) build.running = true
  }

  Process {
    id: build
    command: [root.launcher, "build"]
    stderr: StdioCollector { id: buildErrors; waitForEnd: true }
    onExited: function(code) {
      if (code !== 0) root.notify(buildErrors.text.trim() || "Could not apply agents.json.")
    }
  }

  // The shell also tears plugins down when it restarts or the session ends,
  // so this only cleans up once the shell, still running a moment later, no
  // longer lists the plugin as enabled. It runs from bash -c because a
  // removed plugin's folder (and its launcher) may already be gone.
  Component.onDestruction: {
    Quickshell.execDetached(["bash", "-c",
      'sleep 3\n'
      + 'state=$(omarchy plugin list --json 2>/dev/null | jq -r --arg id "$1" \'[.[] | select(.id == $id)][0].enabled // "absent"\') || exit 0\n'
      + '[[ -n $state && $state != true ]] || exit 0\n'
      + 'pkill -f -- "--user-data-dir=$2/profile" || true\n'
      + 'hyprctl reload >/dev/null 2>&1 || true\n',
      "agents-drawer-cleanup", pluginId, dataDir])
  }
}
