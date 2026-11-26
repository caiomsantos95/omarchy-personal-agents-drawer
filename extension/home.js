const themeEl = document.getElementById("theme");
const grid = document.getElementById("chats");
let enabled = [];

async function text(p) {
  try {
    const r = await fetch(p);
    return r.ok ? r.text() : "";
  } catch {
    return "";
  }
}

let lastTheme = "";
async function loadTheme() {
  const theme = await text("theme.css");
  if (theme && theme !== lastTheme) {
    lastTheme = theme;
    themeEl.textContent = theme;
    if (tabbar) tabbar.setCss(theme + "\n" + barCss);
  }
}

function render() {
  grid.replaceChildren();
  for (const chat of CHATS) {
    const on = enabled.includes(chat.id);
    const tile = document.createElement("div");
    tile.className = "chat" + (on ? " on" : "");
    tile.tabIndex = 0;
    tile.title = on ? `Open ${chat.name}` : `Enable ${chat.name}`;
    tile.setAttribute("role", "button");
    tile.setAttribute("aria-label", tile.title);

    const img = document.createElement("img");
    img.alt = "";
    img.src = chat.icon;
    img.onerror = () => {
      const f = document.createElement("span");
      f.className = "fallback";
      f.textContent = chat.label[0];
      img.replaceWith(f);
    };

    const tag = document.createElement("span");
    tag.className = "tag";
    tag.textContent = chat.label;

    tile.append(img, tag);
    if (on) {
      const off = document.createElement("button");
      off.className = "off";
      off.textContent = "×";
      off.title = `Disable ${chat.name}`;
      off.addEventListener("click", async (e) => {
        e.stopPropagation();
        apply(await chrome.runtime.sendMessage({ type: "disable", id: chat.id }));
      });
      tile.append(off);
    }

    const open = async () => apply(await chrome.runtime.sendMessage({ type: "open", id: chat.id }));
    tile.addEventListener("click", open);
    tile.addEventListener("keydown", (e) => (e.key === "Enter" || e.key === " ") && open());
    grid.append(tile);
  }
}

function apply(s) {
  if (!s) return;
  enabled = s.enabled || [];
  render();
  tabbar && tabbar.update(s);
}

let tabbar = null;
let barCss = "";
(async () => {
  barCss = await text("tabbar.css");
  await loadTheme();
  tabbar = mountTabbar(document.getElementById("omarchy-tabbar"), lastTheme + "\n" + barCss);
  chrome.runtime.onMessage.addListener((m) => m && m.type === "state" && apply(m));
  apply(await chrome.runtime.sendMessage({ type: "state" }));
  setInterval(() => document.visibilityState === "visible" && loadTheme(), 3000);
  window.addEventListener("focus", loadTheme);
})();
