import "phoenix_html";
import { Socket } from "phoenix";
import { LiveSocket } from "phoenix_live_view";

let csrfToken = document
  .querySelector("meta[name='csrf-token']")
  .getAttribute("content");

let liveSocket = new LiveSocket("/live", Socket, {
  params: { _csrf_token: csrfToken },
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
