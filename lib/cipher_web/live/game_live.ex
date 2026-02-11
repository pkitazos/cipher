defmodule CipherWeb.GameLive do
  use CipherWeb, :live_view

  # This is called when the LiveView loads.
  # We initialize with `game_id: nil`
  def mount(_params, _session, socket) do
    {:ok, assign(socket, game_id: nil)}
  end

  # The `render/1` function returns the HTML.
  # It uses `@game_id` from socket assigns
  def render(assigns) do
    ~H"""
    <div class="max-w-md mx-auto text-center">
      <h1 class="text-3xl font-bold mb-8">Cipher</h1>

      <.button phx-click="start_game">
        Start Game
      </.button>

      <div :if={@game_id} class="mt-8 p-4 bg-zinc-100 rounded">
        <p class="text-sm text-zinc-600">Game ID</p>
        <p class="font-mono text-lg">{@game_id}</p>
      </div>
    </div>
    """
  end

  # In LiveView events are handled using the `handle_event/3` function
  # Whatever we call our event, in this case `"start_game"` is what we match on
  def handle_event("start_game", _params, socket) do
    # TODO: Actually create a game
    {:noreply, assign(socket, game_id: "placeholder-id")}
  end
end
