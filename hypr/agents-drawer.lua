-- Personal Agents Drawer: your agents' web apps (Claude Duet, Muse, ChatGPT
-- Dots, or any you add to agents.json) as
-- pre-rendered browser windows in a drawer that slides in from the right edge
-- over any workspace, without retiling what is underneath.
--
--   SUPER + D                         toggle the drawer
--   rest the pointer on a right edge  open it
--   click outside the drawer          close it
--   Alt+0..9 inside the drawer        switch agents (handled by the extension)
--
-- Every drawer window floats in special:agents, stacked in one panel: the
-- home window (agent logos header) on top, shrunk to the header while an
-- agent is showing, and the agent windows under it, the current one raised.
--
-- Installed by install.sh from the plugin folder; the rest lives in
-- ~/.local/bin/agents-drawer and ~/.local/share/agents-drawer/.

agents_drawer = agents_drawer or {}
local M = agents_drawer

local NAME = "agents"
local WS = "special:" .. NAME

local HOME = os.getenv("HOME") or ""
local DATA = (os.getenv("XDG_DATA_HOME") or (HOME .. "/.local/share")) .. "/agents-drawer"

-- Chromium names an --app window's Wayland app id after its URL. The home
-- window's is fixed; the agents' come from agents.lua, which
-- `agents-drawer build` generates from agents.json.
local APPS = { home = { class = "chrome-agents-drawer.invalid__-Default" } }
local ok, agents = pcall(dofile, DATA .. "/agents.lua")
if ok and type(agents) == "table" then
  for _, a in ipairs(agents) do
    if type(a.id) == "string" and a.id:match("^[a-z0-9][a-z0-9-]*$") and type(a.class) == "string" then
      APPS[a.id] = { class = a.class }
    end
  end
end

local KEY = "SUPER + D"
local SHARE = 0.34 -- of the monitor's usable width
local MIN_WIDTH = 480
local GAP = 10 -- from the screen edges, matching Omarchy's gaps_out
local HEADER = 132 -- header height, matches --om-header-h in the extension
local HEADER_GAP = 4

local EDGE_TICK_MS = 75
local EDGE_DWELL_MS = 450

local LAUNCHER = HOME .. "/.local/bin/agents-drawer"

-- Which window is showing survives Hyprland config reloads (which start a
-- fresh Lua state) so it stays in step with the header the extension draws.
local STATE = DATA .. "/current"

local function remembered()
  local f = io.open(STATE, "r")
  if not f then
    return nil
  end
  local id = f:read("l")
  f:close()
  return id and APPS[id] and id or nil
end

local function remember(id)
  local f = io.open(STATE, "w")
  if f then
    f:write(id, "\n")
    f:close()
  end
end

M.current = M.current or remembered() or "home"
M.launching = M.launching or {}

local function escape(s)
  return (s:gsub("%.", "\\."))
end

for _, app in pairs(APPS) do
  o.window("^" .. escape(app.class) .. "$", { float = true, workspace = WS .. " silent" })
end

hl.workspace_rule({ workspace = WS, animation = "slide right" })

local function window_of(id)
  local class = APPS[id] and APPS[id].class
  for _, w in ipairs(hl.get_windows()) do
    if w.class == class then
      return w
    end
  end
end

local function app_of(window)
  for id, app in pairs(APPS) do
    if window and window.class == app.class then
      return id
    end
  end
end

local function visible()
  local ws = hl.get_workspace(WS)
  return ws ~= nil and ws.visible
end

local function usable(mon)
  return mon and mon.scale and mon.scale > 0
end

local function border()
  return hl.get_config("general.border_size") or 0
end

-- Logical size of a monitor, accounting for scale and quarter-turn transforms.
local function logical(mon)
  local w, h = mon.width, mon.height
  if mon.transform % 2 == 1 then
    w, h = h, w
  end
  return w / mon.scale, h / mon.scale
end

local function drawer_monitor()
  local ws = hl.get_workspace(WS)
  if ws and ws.visible and usable(ws.monitor) then
    return ws.monitor
  end
  return hl.get_active_monitor()
end

-- The panel's outer rectangle (borders included) on a monitor.
local function panel(mon)
  local w, h = logical(mon)
  local r = mon.reserved
  local width = math.max(MIN_WIDTH, math.floor((w - r.left - r.right) * SHARE))
  local x = mon.x + w - r.right - GAP - width
  local y = mon.y + r.top + GAP
  return x, y, width, h - r.top - r.bottom - 2 * GAP
end

local function place(win, x, y, w, h)
  local bw = border()
  local target = "address:" .. win.address
  hl.dispatch(hl.dsp.window.resize({ x = math.floor(w - 2 * bw), y = math.floor(h - 2 * bw), window = target }))
  hl.dispatch(hl.dsp.window.move({ x = math.floor(x + bw), y = math.floor(y + bw), window = target }))
end

function M.layout(mon)
  mon = mon or drawer_monitor()
  if not usable(mon) then
    return
  end
  local x, y, w, h = panel(mon)
  local header = HEADER + 2 * border()
  for id in pairs(APPS) do
    local win = window_of(id)
    if win then
      if id ~= "home" then
        place(win, x, y + header + HEADER_GAP, w, h - header - HEADER_GAP)
      elseif M.current == "home" then
        place(win, x, y, w, h)
      else
        place(win, x, y, w, header)
      end
    end
  end
end

-- Raise and focus the current window. Focusing a window in a hidden special
-- workspace would open it, so this only runs while the drawer is showing.
local function front()
  local win = window_of(M.current) or window_of("home")
  if not (win and visible()) then
    return
  end
  local target = "address:" .. win.address
  hl.dispatch(hl.dsp.window.alter_zorder({ mode = "top", window = target }))
  hl.dispatch(hl.dsp.focus({ window = target }))
end

-- Open an agent's window in the background if it is not running yet.
function M.ensure(id)
  local app = APPS[id]
  if not app or window_of(id) or M.launching[id] then
    return
  end
  if id == "home" then
    hl.exec_cmd(LAUNCHER .. " start")
  else
    hl.exec_cmd(LAUNCHER .. " app " .. o.shell_quote(id))
  end
  M.launching[id] = true
  hl.timer(function()
    M.launching[id] = nil
  end, { timeout = 15000, type = "oneshot" })
end

function M.show(id)
  if not APPS[id] then
    return
  end
  M.current = id
  remember(id)
  M.ensure(id)
  M.layout()
  front()
end

function M.close(id)
  local win = id ~= "home" and window_of(id)
  if win then
    hl.dispatch(hl.dsp.window.close({ window = "address:" .. win.address }))
  end
  if M.current == id then
    M.show("home")
  end
end

function M.open()
  if visible() then
    return
  end
  M.ensure("home")
  hl.dispatch(hl.dsp.workspace.toggle_special(NAME))
end

function M.hide()
  if visible() then
    hl.dispatch(hl.dsp.workspace.toggle_special(NAME))
  end
end

function M.toggle()
  if visible() then
    M.hide()
  else
    M.open()
  end
end

o.bind(KEY, "Personal Agents Drawer", function()
  M.toggle()
end)

-- Click outside the drawer to close it, like pressing the shortcut. The bind
-- is non-consuming, so the click still reaches the window it lands on. Focus
-- follows the mouse in Omarchy, so a click, not a focus change, is the signal.
local function over_drawer(p)
  local bw = border()
  for _, w in ipairs(hl.get_windows()) do
    if w.workspace and w.workspace.name == WS then
      local x, y = w.at.x - bw, w.at.y - bw
      if p.x >= x and p.x <= x + w.size.x + 2 * bw and p.y >= y and p.y <= y + w.size.y + 2 * bw then
        return true
      end
    end
  end
  return false
end

hl.bind("mouse:272", function()
  if not visible() then
    return
  end
  local p = hl.get_cursor_pos()
  if p and not over_drawer(p) then
    M.hide()
  end
end, { non_consuming = true, description = "Close Personal Agents Drawer on an outside click" })

hl.on("workspace.special_active", function(ws, mon)
  if ws and ws.name == WS then
    M.layout(mon)
    front()
  end
end)

hl.on("window.open", function(win)
  local id = app_of(win)
  if not id then
    return
  end
  M.launching[id] = nil
  -- One window per agent: a second one (a restored session, a double launch)
  -- is closed.
  for _, other in ipairs(hl.get_windows()) do
    if other.class == win.class and other.address ~= win.address then
      hl.dispatch(hl.dsp.window.close({ window = "address:" .. win.address }))
      return
    end
  end
  M.layout()
  front()
end)

hl.on("monitor.layout_changed", function()
  if visible() then
    M.layout()
  end
end)

-- Rest the pointer on the right edge of a screen (away from the corners) to
-- open the drawer. It re-arms once the pointer leaves the edge, and stays
-- out of the way of fullscreen windows.
local dwell, armed = 0, true

local function edge_tick()
  local p = hl.get_cursor_pos()
  local mon = hl.get_monitor_at_cursor()
  if not (p and usable(mon)) then
    return
  end
  local w, h = logical(mon)
  local at_edge = p.x >= mon.x + w - 2 and p.y >= mon.y + h * 0.15 and p.y <= mon.y + h * 0.85
  if not at_edge then
    dwell, armed = 0, true
    return
  end
  if not armed or visible() then
    return
  end
  local active = mon.active_workspace
  if active and active.has_fullscreen then
    return
  end
  dwell = dwell + EDGE_TICK_MS
  if dwell >= EDGE_DWELL_MS then
    armed = false
    M.open()
  end
end

if M.edge_timer then
  M.edge_timer:set_enabled(false)
end
M.edge_timer = hl.timer(edge_tick, { timeout = EDGE_TICK_MS, type = "repeat" })

-- Pre-render: start the drawer browser with the desktop, hidden.
hl.on("hyprland.start", function()
  M.ensure("home")
end)
