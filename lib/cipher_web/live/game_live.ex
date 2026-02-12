defmodule CipherWeb.GameLive do
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
    with {:ok, game_id} <- Game.Server.start_game(socket.assigns.difficulty),
         {:ok, game_state} <- Game.Server.get_client_state(game_id) do
      socket =
        socket
        |> assign(game: Map.drop(game_state, [:secret]))
        |> assign(guess: %{})

      {:noreply, socket}
    else
      {:error, reason} -> {:noreply, put_flash(socket, :error, "Failed to start game: #{reason}")}
    end
  end

  def handle_event("set_difficulty", %{"difficulty" => difficulty}, socket) do
    {:noreply, assign(socket, difficulty: String.to_existing_atom(difficulty))}
  end

  def handle_event("select_choice", %{"kind" => kind, "choice" => choice_name}, socket) do
    kind = String.to_existing_atom(kind)
    choice_name = String.to_existing_atom(choice_name)

    choice_map = Game.get_choices_by_kind(kind)
    choice = choice_map[choice_name]

    updated_guess = Map.update(socket.assigns.guess, kind, choice, fn _ -> choice end)
    IO.inspect(updated_guess, label: "current guess")

    {:noreply, assign(socket, guess: updated_guess)}
  end

  def handle_event("make_guess", _params, %{assigns: %{guess: guess, game: game}} = socket) do
    with {:ok, guess_mapset} <- Game.convert_guess_from_choices(guess, game.difficulty),
         {:ok, updated_state} <- Game.Server.guess(game.id, guess_mapset) do
      flash_message =
        if updated_state.status == :won,
          do: "Correct! You won!",
          else: "You got #{updated_state.last_matches} matches."

      socket =
        socket
        |> put_flash(:info, flash_message)
        |> assign(game: updated_state, guess: %{})

      {:noreply, socket}
    end
  end

  defp difficulty_class(:easy), do: "text-green-500"
  defp difficulty_class(:normal), do: "text-blue-500"
  defp difficulty_class(:hard), do: "text-red-500"

  defp status_class(:active), do: "text-lime-500"
  defp status_class(:won), do: "text-indigo-400"
  defp status_class(:expired), do: "text-red-500"

  defp sort_guess(guess) do
    guess
    |> MapSet.to_list()
    |> Enum.sort(&Game.Choice.compare/2)
  end
end
