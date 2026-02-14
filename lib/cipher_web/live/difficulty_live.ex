defmodule CipherWeb.DifficultyLive do
  use CipherWeb, :live_view

  alias Cipher.Game

  # This is called when the LiveView loads.
  # We initialize with `game_id: nil`
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(game: nil)
      |> assign(difficulty: nil)
      |> assign(guess: nil)

    {:ok, socket}
  end

  # In LiveView events are handled using the `handle_event/3` function
  # Whatever we call our event, in this case `"start_game"` is what we match on
  def handle_event("start_game", _params, socket) do
    case Game.Server.start_game(socket.assigns.difficulty) do
      {:ok, game_id} ->
        {:noreply, push_navigate(socket, to: ~p"/game/#{game_id}")}

      {:error, reason} ->
        {:noreply, put_flash(socket, :error, "Failed to start game: #{reason}")}
    end
  end

  def handle_event("set_difficulty", %{"difficulty" => difficulty}, socket) do
    {:noreply, assign(socket, difficulty: String.to_existing_atom(difficulty))}
  end
end
