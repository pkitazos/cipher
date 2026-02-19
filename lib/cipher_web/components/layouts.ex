defmodule CipherWeb.Layouts do
  use CipherWeb, :html

  embed_templates "layouts/*"

  # Layouts

  attr :flash, :map, required: true
  attr :current_scope, :map, default: nil
  slot :inner_block

  def app(assigns) do
    ~H"""
    <header class="h-16 w-full border-b border-base-300 bg-base-100 dark:bg-base-100 items-center flex">
      <div class="max-w-7xl w-full mx-auto px-4 flex items-center justify-between my-auto">
        <.link navigate={~p"/"} class="text-xl font-bold text-base-content font-mono">
          Cipher
        </.link>
        <.user_menu current_scope={@current_scope} />
      </div>
    </header>
    <main class="w-full mx-auto flex-1 px-0">
      <.flash_group flash={@flash} />
      {render_slot(@inner_block)}
    </main>
    """
  end

  attr :flash, :map, required: true
  attr :current_scope, :map, default: nil
  attr :game, :map, required: true
  slot :inner_block

  def game(assigns) do
    ~H"""
    <.game_header game={@game} current_scope={@current_scope} />
    <main class="w-full mx-auto flex-1 px-0">
      <.flash_group flash={@flash} />
      {render_slot(@inner_block)}
    </main>
    """
  end

  # User menu

  attr :current_scope, :map, default: nil

  defp user_menu(assigns) do
    ~H"""
    <div class="dropdown dropdown-end">
      <div tabindex="0" role="button" class="btn btn-ghost btn-circle btn-sm">
        <.icon name="hero-user-circle" class="w-6 h-6 text-base-content/50" />
      </div>
      <div
        tabindex="0"
        class="dropdown-content z-20 w-56 p-2 shadow-lg bg-base-300 border border-base-300 rounded-lg"
      >
        <%= if @current_scope do %>
          <div class="px-3 py-2">
            <p class="text-sm font-medium text-base-content truncate">
              {@current_scope.user.email}
            </p>
          </div>
          <div class="divider my-0" />
          <ul class="menu menu-sm p-0 w-full">
            <li class="w-full">
              <.link href={~p"/users/settings"} class="text-sm w-full">
                <.icon name="hero-cog-6-tooth-micro" class="w-4 h-4" /> Settings
              </.link>
            </li>
            <li class="w-full">
              <.link href={~p"/users/log-out"} method="delete" class="text-sm w-full">
                <.icon name="hero-arrow-right-start-on-rectangle-micro" class="w-4 h-4" /> Log out
              </.link>
            </li>
          </ul>
        <% else %>
          <ul class="menu menu-sm p-0">
            <li>
              <.link href={~p"/users/register"} class="text-sm">
                <.icon name="hero-user-plus-micro" class="w-4 h-4" /> Register
              </.link>
            </li>
            <li>
              <.link href={~p"/users/log-in"} class="text-sm">
                <.icon name="hero-arrow-right-end-on-rectangle-micro" class="w-4 h-4" /> Log in
              </.link>
            </li>
          </ul>
        <% end %>
      </div>
    </div>
    """
  end

  # Game header

  attr :game, :map, required: true
  attr :current_scope, :map, default: nil

  defp game_header(assigns) do
    ~H"""
    <header class="w-full h-16 border-b border-base-300 bg-base-100">
      <div class="max-w-7xl mx-auto px-4 py-3 flex items-center justify-between">
        <div class="flex items-center gap-3">
          <.link
            navigate={~p"/"}
            class="text-base-content/40 hover:text-base-content transition-colors"
          >
            <.icon name="hero-arrow-left" class="w-5 h-5" />
          </.link>
          <div>
            <h1 class="text-xl font-bold text-base-content font-mono leading-tight">Cipher</h1>
            <p class="text-xs text-base-content/50">
              Game #{@game.id} · {@game.difficulty}
            </p>
          </div>
        </div>

        <div class="flex items-center gap-2">
          <.instructions_dropdown />

          <div class="text-right px-2">
            <p class="text-xs text-base-content/50">Guesses</p>
            <p class="text-xl font-bold text-base-content leading-tight">
              {length(@game.guesses)}
            </p>
          </div>

          <div class="w-px h-8 bg-base-300" />

          <.user_menu current_scope={@current_scope} />
        </div>
      </div>
    </header>
    """
  end

  defp instructions_dropdown(assigns) do
    ~H"""
    <div class="dropdown dropdown-end tooltip tooltip-left" data-tip="How to Play">
      <div tabindex="0" role="button" class="btn btn-ghost btn-circle btn-sm">
        <.icon name="hero-question-mark-circle" class="w-5 h-5 text-base-content/50" />
      </div>
      <div
        tabindex="0"
        class="dropdown-content z-20 w-72 p-4 shadow-lg bg-base-100 border border-base-300 rounded-lg"
      >
        <h3 class="text-sm font-semibold text-base-content mb-2">How to Play</h3>
        <ul class="text-xs text-base-content/60 space-y-1 leading-relaxed list-disc ml-4">
          <li>Select one option from each category</li>
          <li>Submit your guess</li>
          <li>Use the match count to deduce the secret</li>
        </ul>
      </div>
    </div>
    """
  end

  # ---------------------------------------------------------------------------
  # Shared components
  # ---------------------------------------------------------------------------

  def flash_group(assigns) do
    ~H"""
    <div id="flash-group" aria-live="polite">
      <.flash kind={:info} flash={@flash} />
      <.flash kind={:error} flash={@flash} />

      <.flash
        id="client-error"
        kind={:error}
        title="We can't find the internet"
        phx-disconnected={show(".phx-client-error #client-error") |> JS.remove_attribute("hidden")}
        phx-connected={hide("#client-error") |> JS.set_attribute({"hidden", ""})}
        hidden
      >
        Attempting to reconnect
        <.icon name="hero-arrow-path" class="ml-1 size-3 motion-safe:animate-spin" />
      </.flash>

      <.flash
        id="server-error"
        kind={:error}
        title="Something went wrong!"
        phx-disconnected={show(".phx-server-error #server-error") |> JS.remove_attribute("hidden")}
        phx-connected={hide("#server-error") |> JS.set_attribute({"hidden", ""})}
        hidden
      >
        Attempting to reconnect
        <.icon name="hero-arrow-path" class="ml-1 size-3 motion-safe:animate-spin" />
      </.flash>
    </div>
    """
  end

  def theme_toggle(assigns) do
    ~H"""
    <div class="flex items-center gap-1 rounded-full border-2 border-base-300 bg-base-300 p-0.5">
      <button
        class="btn btn-ghost btn-xs btn-circle"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="system"
        title="System theme"
      >
        <.icon name="hero-computer-desktop-micro" class="size-4" />
      </button>
      <button
        class="btn btn-ghost btn-xs btn-circle"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="myCoolTheme"
        title="Light theme"
      >
        <.icon name="hero-sun-micro" class="size-4" />
      </button>
      <button
        class="btn btn-ghost btn-xs btn-circle"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="dark"
        title="Dark theme"
      >
        <.icon name="hero-moon-micro" class="size-4" />
      </button>
    </div>
    """
  end
end
