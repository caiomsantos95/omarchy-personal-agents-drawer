// The chats the drawer knows about. Order here is the tab order and the
// Alt+<n> shortcut number.
const CHATS = [
  {
    id: "duet",
    name: "Claude Duet",
    label: "Claude",
    url: "https://claude.ai/duet",
    hosts: ["claude.ai"],
    icon: "https://claude.ai/favicon.ico",
    css: "sites/claude.css",
  },
  {
    id: "muse",
    name: "Muse",
    label: "Muse",
    url: "https://muse.ai/",
    hosts: ["muse.ai", "www.muse.ai"],
    icon: "https://muse.ai/favicon.ico",
    css: "sites/muse.css",
  },
];

function chatForHost(host) {
  return CHATS.find((c) => c.hosts.includes(host));
}
