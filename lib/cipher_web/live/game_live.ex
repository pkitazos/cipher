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
         {:ok, game_state} <- Game.Server.join_game(game_id) do
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
    # The guess is already in socket.assigns.guess as a map of Choice structs

    with {:ok, guess_mapset} <- Game.convert_guess_from_choices(guess, game.difficulty),
         result <- Game.Server.guess(game.id, guess_mapset),
         # Fetch the updated state from the Server (single source of truth)
         {:ok, updated_game_state} <- Game.Server.join_game(game.id) do
      # Filter secret from state
      safe_game_state = Map.drop(updated_game_state, [:secret])

      case result do
        {:correct, _matches} ->
          socket =
            socket
            |> put_flash(:info, "Correct! You won!")
            |> assign(game: safe_game_state)
            |> assign(guess: %{})

          {:noreply, socket}

        {:incorrect, matches} ->
          socket =
            socket
            |> put_flash(:info, "#{matches} matches. Try again!")
            |> assign(game: safe_game_state)
            |> assign(guess: %{})

          {:noreply, socket}

        {:error, reason} ->
          {:noreply, put_flash(socket, :error, "Guess failed: #{inspect(reason)}")}
      end
    else
      {:error, reason} ->
        {:noreply, put_flash(socket, :error, "Invalid guess: #{inspect(reason)}")}
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
