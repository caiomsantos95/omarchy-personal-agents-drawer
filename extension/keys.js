// Alt+0 goes home, Alt+1..9 picks a chat. Works in every drawer window.
window.addEventListener(
  "keydown",
  (e) => {
    if (e.altKey && !e.ctrlKey && !e.metaKey && !e.shiftKey && /^Digit[0-9]$/.test(e.code)) {
      e.preventDefault();
      e.stopPropagation();
      chrome.runtime.sendMessage({ type: "nth", n: Number(e.code.slice(5)) }).catch(() => {});
    }
  },
  true,
);
