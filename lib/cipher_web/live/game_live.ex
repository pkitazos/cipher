defmodule CipherWeb.GameLive do
  use CipherWeb, :live_view

  alias Cipher.Game

  # This is called when the LiveView loads.
  # We initialize with `game_id: nil`
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(game_id: nil)
      |> assign(difficulty: nil)

    {:ok, socket}
  end

  # The `render/1` function returns the HTML.
  # It uses `@game_id` from socket assigns
  def render(assigns) do
    ~H"""
    <div class="max-w-md mx-auto text-center flex flex-col gap-8 justify-center items-center">
      <h1 class="text-3xl font-bold mb-8">Cipher</h1>

      <div class="flex flex-row gap-2">
        <.button phx-click="set_difficulty" phx-value-difficulty="easy" class="bg-red-700 w-24">
            easy
        </.button>
        <.button phx-click="set_difficulty" phx-value-difficulty="normal" class="bg-red-700 w-24">
            normal
        </.button>
        <.button phx-click="set_difficulty" phx-value-difficulty="hard" class="bg-red-700 w-24">
        hard
        </.button>
      </div>

      <.button disabled={@difficulty == nil} phx-click="start_game" class="w-76">
        Start Game
      </.button>

      <div :if={@game_id} class="mt-8 p-4 bg-zinc-100 rounded">
        <p class="text-sm text-zinc-600">Game ID</p>
        <p class="font-mono text-lg">{@game_id}</p>
        <p class="mt-4 text-sm text-zinc-600">Difficulty</p>
        <p class={["font-mono text-lg", difficulty_class(@difficulty)]}>{@difficulty}</p>
      </div>
    </div>
    """
  end

  # In LiveView events are handled using the `handle_event/3` function
  # Whatever we call our event, in this case `"start_game"` is what we match on
  def handle_event("start_game", _params, socket) do
    case Game.Server.start_game(socket.assigns.difficulty) do
      {:ok, game_id} ->
        {:noreply, assign(socket, game_id: game_id)}

      {:error, reason} ->
        {:noreply, put_flash(socket, :error, "Failed to start game: #{reason}")}
    end
  end

  def handle_event("set_difficulty", %{"difficulty" => difficulty}, socket) do
    {:noreply, assign(socket, difficulty: String.to_existing_atom(difficulty))}
  end

  defp difficulty_class(:easy), do: "text-green-500"
  defp difficulty_class(:normal), do: "text-blue-500"
  defp difficulty_class(:hard), do: "text-red-500"
end
