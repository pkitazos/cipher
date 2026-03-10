import "phoenix_html";
import { Socket } from "phoenix";
import { LiveSocket } from "phoenix_live_view";

let csrfToken = document
  .querySelector("meta[name='csrf-token']")
  .getAttribute("content");

let Hooks = {};

Hooks.CopyToClipboard = {
  mounted() {
    this.el.addEventListener("click", () => {
      const difficulty = this.el.dataset.difficulty;
      const secretSize = parseInt(this.el.dataset.secretSize);
      const matches = JSON.parse(this.el.dataset.matches);

      const isDark =
        document.documentElement.getAttribute("data-theme") === "dark";
      const filled = "🔵";
      const empty = isDark ? "⚫" : "⚪";

      const rows = matches
        .map((m) => filled.repeat(m) + empty.repeat(secretSize - m))
        .join("\n");

      const guessWord = matches.length === 1 ? "guess" : "guesses";
      const label = difficulty.charAt(0).toUpperCase() + difficulty.slice(1);
      const text = `🔐 Cipher (${label}) — ${matches.length} ${guessWord}\n\n${rows}`;

      navigator.clipboard.writeText(text).then(() => {
        const original = this.el.innerHTML;
        this.el.innerHTML =
          '<svg xmlns="http://www.w3.org/2000/svg" class="w-4 h-4" viewBox="0 0 20 20" fill="currentColor"><path fill-rule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" clip-rule="evenodd"/></svg> Copied!';
        setTimeout(() => {
          this.el.innerHTML = original;
        }, 2000);
      });
    });
  },
};

Hooks.ScrollToBottom = {
  mounted() {
    this.scrollToBottom();
  },
  updated() {
    this.scrollToBottom();
  },
  scrollToBottom() {
    this.el.scrollTop = this.el.scrollHeight;
  },
};

let liveSocket = new LiveSocket("/live", Socket, {
  params: { _csrf_token: csrfToken },
  hooks: Hooks,
});

// Connect if there are any LiveViews on the page
liveSocket.connect();

// Expose liveSocket on window for debugging in browser console
window.liveSocket = liveSocket;

function getThemePreference() {
  return localStorage.getItem("theme") || "system";
}

function applyTheme(preference) {
  const theme =
    preference === "system"
      ? window.matchMedia("(prefers-color-scheme: dark)").matches
        ? "dark"
        : "myCoolTheme"
      : preference;

  document.documentElement.setAttribute("data-theme", theme);
}

applyTheme(getThemePreference());

window
  .matchMedia("(prefers-color-scheme: dark)")
  .addEventListener("change", () => {
    if (getThemePreference() === "system") applyTheme("system");
  });

window.addEventListener("phx:set-theme", (e) => {
  const preference = e.target.dataset.phxTheme || "system";
  localStorage.setItem("theme", preference);
  applyTheme(preference);
});
