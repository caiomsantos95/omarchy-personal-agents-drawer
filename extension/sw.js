importScripts("agents.js");

// Each chat is its own Chromium app window; Hyprland stacks them in the
// drawer (~/.config/hypr/agents-drawer.lua). This worker keeps which chats are
// enabled and which one is showing, and relays switches to Hyprland through
// the native host.
const HOME = chrome.runtime.getURL("home.html");
const PLACEHOLDER = "https://agents-drawer.invalid/";
const HOST = "io.github.caiomsantos95.agents_drawer";

async function getState() {
  const { enabled = [], current = "home" } = await chrome.storage.local.get(["enabled", "current"]);
  return { enabled: CHATS.map((c) => c.id).filter((id) => enabled.includes(id)), current };
}

function hypr(cmd, app) {
  return chrome.runtime.sendNativeMessage(HOST, { cmd, app }).catch((e) => ({ ok: false, error: String(e) }));
}

async function broadcast() {
  const s = await getState();
  for (const t of await chrome.tabs.query({})) chrome.tabs.sendMessage(t.id, { type: "state", ...s }).catch(() => {});
}

async function show(app) {
  await chrome.storage.local.set({ current: app });
  await hypr("show", app);
}

// Open every enabled chat in the background so the drawer shows a page that
// is already loaded.
async function prerender() {
  const s = await getState();
  for (const id of s.enabled) await hypr("ensure", id);
  // Line Hyprland's stack up with the header: same agent in front.
  await hypr("show", s.enabled.includes(s.current) ? s.current : "home");
}

// Chromium will not open an extension page with --app, so the launcher opens
// the drawer window on a placeholder address and the home page is swapped in.
async function claimPlaceholder(tabId, url) {
  if (url && url.startsWith(PLACEHOLDER)) {
    await chrome.tabs.update(tabId, { url: HOME });
    prerender();
  }
}
chrome.tabs.onUpdated.addListener((tabId, info, tab) => claimPlaceholder(tabId, info.url || tab.url));
chrome.tabs.query({}).then((tabs) => tabs.forEach((t) => claimPlaceholder(t.id, t.url || t.pendingUrl)));

chrome.runtime.onMessage.addListener((msg, _sender, reply) => {
  (async () => {
    const s = await getState();
    if (msg.type === "open" && CHATS.some((c) => c.id === msg.id)) {
      if (!s.enabled.includes(msg.id)) await chrome.storage.local.set({ enabled: [...s.enabled, msg.id] });
      await show(msg.id);
    } else if (msg.type === "home") {
      await show("home");
    } else if (msg.type === "hide") {
      await hypr("hide", "home");
    } else if (msg.type === "disable") {
      await chrome.storage.local.set({ enabled: s.enabled.filter((id) => id !== msg.id) });
      await hypr("close", msg.id);
      if (s.current === msg.id) await show("home");
    } else if (msg.type === "nth") {
      if (msg.n === 0) await show("home");
      else if (s.enabled[msg.n - 1]) await show(s.enabled[msg.n - 1]);
    }
    if (msg.type !== "state") await broadcast();
    reply(await getState());
  })();
  return true;
});
