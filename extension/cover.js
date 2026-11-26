// Injected into every chat page in the drawer: pulls in the Omarchy theme
// variables plus the site's cover CSS, kept last in <head> so it wins.
(() => {
  const chat = chatForHost(location.hostname);
  if (!chat) return;

  const get = (p) => fetch(chrome.runtime.getURL(p)).then((r) => (r.ok ? r.text() : "")).catch(() => "");

  const style = document.createElement("style");
  style.id = "omarchy-cover";
  const attach = () => {
    const parent = document.head || document.documentElement;
    if (style.parentNode !== parent || parent.lastElementChild !== style) parent.appendChild(style);
  };

  let last = "";
  async function load() {
    const css = [await get("theme.css"), await get("base.css"), chat.css ? await get(chat.css) : ""].join("\n");
    if (css !== last) style.textContent = last = css;
    attach();
  }

  new MutationObserver(attach).observe(document.documentElement, { childList: true });
  const watchHead = () => document.head && new MutationObserver(attach).observe(document.head, { childList: true });
  if (document.head) watchHead();
  else document.addEventListener("DOMContentLoaded", watchHead, { once: true });

  load();
  // Follow theme switches: theme.css is rewritten by the theme-set hook.
  setInterval(() => document.visibilityState === "visible" && load(), 3000);
  window.addEventListener("focus", load);
})();
