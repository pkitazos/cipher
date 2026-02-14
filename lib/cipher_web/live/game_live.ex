defmodule CipherWeb.GameLive do
  use CipherWeb, :live_view

  alias CipherWeb.GameComponents
  alias Cipher.Games.Server, as: GameServer
  alias Cipher.Games.Logic, as: GameLogic
  alias Cipher.Games.Choice
  alias Cipher.Games

  def mount(%{"game_id" => id}, _session, socket) do
    case Games.get_running_game(String.to_integer(id)) do
      {:ok, game} ->
        {:ok, assign(socket, game: game, guess: %{})}

      {:error, :not_found} ->
        {:ok,
         socket
         |> put_flash(:error, "Game not found")
         |> push_navigate(to: ~p"/")}
    end
  end

  def handle_event("select_choice", %{"kind" => kind, "choice" => choice_name}, socket) do
    kind = String.to_existing_atom(kind)
    choice_name = String.to_existing_atom(choice_name)

    choice_map = GameLogic.get_choices_by_kind(kind)
    choice = choice_map[choice_name]

    updated_guess = Map.update(socket.assigns.guess, kind, choice, fn _ -> choice end)
    IO.inspect(updated_guess, label: "current guess")

    {:noreply, assign(socket, guess: updated_guess)}
  end

  def handle_event("make_guess", _params, %{assigns: %{guess: guess, game: game}} = socket) do
    with {:ok, guess_mapset} <- GameLogic.convert_guess_from_choices(guess, game.difficulty),
         {:ok, updated_state} <- GameServer.guess(game.id, guess_mapset) do
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

  # this also feels a little weird it's so similar to the start and restart functions
  def handle_event("level_up", _params, socket) do
    with {:ok, game_id} <- GameServer.level_up(socket.assigns.game.id),
         {:ok, game_state} <- GameServer.get_client_state(game_id) do
      socket =
        socket
        |> assign(game: game_state)
        |> assign(guess: %{})

      {:noreply, socket}
    else
      {:error, reason} -> {:noreply, put_flash(socket, :error, "Failed to start game: #{reason}")}
    end
  end

  defp sort_guess(guess) do
    guess
    |> MapSet.to_list()
    |> Enum.sort(&Choice.compare/2)
  end
end
