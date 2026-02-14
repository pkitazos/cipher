defmodule CipherWeb.DifficultyLive do
  use CipherWeb, :live_view

  alias Cipher.Accounts
  alias Cipher.Games

  # This is called when the LiveView loads.
  # We initialize with `game_id: nil`
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(game: nil)
      |> assign(difficulty: nil)

    {:ok, socket}
  end

  def handle_event("start_game", _params, socket) do
    difficulty = socket.assigns.difficulty

    {:ok, user} = Accounts.create_guest_user()

    case Games.start_new_game(user, difficulty) do
      {:ok, game} ->
        {:noreply, push_navigate(socket, to: ~p"/game/#{game.id}")}

      {:error, _reason} ->
        {:noreply, put_flash(socket, :error, "Something went wrong starting the game.")}
    end
  end

  def handle_event("set_difficulty", %{"difficulty" => difficulty}, socket) do
    {:noreply, assign(socket, difficulty: String.to_existing_atom(difficulty))}
  end
end
