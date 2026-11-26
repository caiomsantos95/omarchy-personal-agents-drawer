// The drawer header, drawn by the home window:
//
//   ◆ Agents                         [hover ▸ edge] [SUPER + D]  ×
//   [logo]  [logo]  [ + ]
//   Claude   Muse    Add
//
// While a chat is showing, Hyprland shrinks the home window to just this
// header and stacks the chat window under it. "Add" opens the home page,
// where chats are switched on and off.
function mountTabbar(host, cssText) {
  const root = host.attachShadow({ mode: "closed" });
  const style = document.createElement("style");
  style.textContent = cssText || "";
  const header = document.createElement("header");
  root.append(style, header);

  let state = { enabled: [], current: "home" };

  const el = (tag, cls, text) => {
    const e = document.createElement(tag);
    if (cls) e.className = cls;
    if (text != null) e.textContent = text;
    return e;
  };

  function tile({ label, icon, glyph, active, hint, onClick }) {
    const b = el("button", "tile" + (active ? " active" : ""));
    b.title = hint;
    const face = el("span", "face");
    if (icon) {
      const img = el("img");
      img.alt = "";
      img.src = icon;
      img.onerror = () => img.replaceWith(el("span", "glyph", label[0]));
      face.append(img);
    } else {
      face.append(el("span", "glyph", glyph));
    }
    b.append(face, el("span", "label", label));
    b.addEventListener("click", onClick);
    return b;
  }

  function render() {
    const top = el("div", "top");
    const title = el("div", "title");
    title.append(el("span", "diamond", "◆"), el("span", null, "Agents"));
    const chips = el("div", "chips");
    chips.append(el("span", "chip", "hover ▸ edge"), el("span", "chip", "SUPER + D"));
    const close = el("button", "close", "×");
    close.title = "Hide (Super+D)";
    close.addEventListener("click", () => send({ type: "hide" }));
    top.append(title, chips, close);

    const row = el("div", "row");
    CHATS.filter((c) => state.enabled.includes(c.id)).forEach((c, i) => {
      row.append(
        tile({
          label: c.label,
          icon: c.icon,
          active: state.current === c.id,
          hint: `${c.name} (Alt+${i + 1})`,
          onClick: () => send({ type: "open", id: c.id }),
        }),
      );
    });
    row.append(
      tile({
        label: "Add",
        glyph: "+",
        active: state.current === "home",
        hint: "Add or remove agents (Alt+0)",
        onClick: () => send({ type: "home" }),
      }),
    );

    header.replaceChildren(top, row);
  }

  async function send(msg) {
    try {
      const s = await chrome.runtime.sendMessage(msg);
      if (s) update(s);
    } catch {}
  }

  function update(s) {
    state = { enabled: s.enabled || [], current: s.current || "home" };
    render();
  }

  render();
  return { setCss: (css) => (style.textContent = css), update };
}
