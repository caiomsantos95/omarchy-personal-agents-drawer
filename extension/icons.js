// Agent logos: the icon URL from agents.json if it loads, else the favicon
// Chromium cached the first time the agent was opened, else null (the caller
// draws the agent's initial instead). Successes are cached; misses are
// retried on the next render, so a logo appears once the agent has loaded.
const Icons = (() => {
  const found = new Map();
  const favicon = (url) => chrome.runtime.getURL(`/_favicon/?pageUrl=${encodeURIComponent(url)}&size=64`);
  const bytes = (src) => fetch(src).then((r) => (r.ok ? r.arrayBuffer() : null)).catch(() => null);
  const loads = (src) =>
    new Promise((done) => {
      const img = new Image();
      img.onload = () => done(img.naturalWidth > 0);
      img.onerror = () => done(false);
      img.src = src;
    });
  const same = (a, b) => {
    if (!a || !b || a.byteLength !== b.byteLength) return false;
    const x = new Uint8Array(a), y = new Uint8Array(b);
    for (let i = 0; i < x.length; i++) if (x[i] !== y[i]) return false;
    return true;
  };
  // Chromium answers with a generic globe for pages it has no icon for.
  let generic = null;

  async function resolve(chat) {
    if (chat.icon && (await loads(chat.icon))) return chat.icon;
    generic ??= await bytes(favicon("https://agents-drawer.invalid/"));
    const own = await bytes(favicon(chat.url));
    return own && !same(own, generic) ? favicon(chat.url) : null;
  }

  return {
    async get(chat) {
      if (found.has(chat.id)) return found.get(chat.id);
      const src = await resolve(chat);
      if (src) found.set(chat.id, src);
      return src;
    },
  };
})();
