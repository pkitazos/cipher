defmodule CipherWeb.GameLive do
  require Logger
  use CipherWeb, :live_view

  alias CipherWeb.Layouts
  alias CipherWeb.ChoiceComponents

  alias Cipher.Games
  alias Cipher.Games.{Choice, Logic}

  def mount(%{"game_id" => id}, _session, socket) do
    case Games.get_running_game(String.to_integer(id)) do
      {:ok, game} ->
        Logger.debug("[game status is] #{game.status}")
        {:ok, assign(socket, game: game, guess: %{})}

      {:error, :not_found} ->
        {:ok,
         socket
         |> put_flash(:error, "Game not found")
         |> push_navigate(to: ~p"/")}
    end
  end

  def handle_event("select_choice", %{"kind" => kind_str, "choice" => choice_name_str}, socket) do
    kind = String.to_existing_atom(kind_str)

    choice =
      choice_name_str
      |> String.to_existing_atom()
      |> Choice.from_name()

    updated_guess = Map.put(socket.assigns.guess, kind, choice)

    {:noreply, assign(socket, guess: updated_guess)}
  end

  def handle_event("deselect_choice", %{"kind" => kind_str}, socket) do
    kind = String.to_existing_atom(kind_str)

    updated_guess = Map.delete(socket.assigns.guess, kind)

    {:noreply, assign(socket, guess: updated_guess)}
  end

  def handle_event("make_guess", _params, %{assigns: %{guess: guess, game: game}} = socket) do
    case Games.make_guess(game.id, guess) do
      {:ok, updated_state} ->
        flash_message =
          if updated_state.status == :won,
            do: "Correct! You won!",
            else: "You got #{updated_state.last_matches} matches."

        socket =
          socket
          |> put_flash(:info, flash_message)
          |> assign(game: updated_state, guess: %{})

        {:noreply, socket}

      {:error, reason} ->
        {:noreply, put_flash(socket, :error, "Guess failed: #{inspect(reason)}")}
    end
  end

  def handle_event("level_up", _params, socket) do
    case Games.level_up(socket.assigns.game.id) do
      {:ok, new_game_state} ->
        socket =
          socket
          |> put_flash(:info, "Level Up! Difficulty: #{new_game_state.difficulty}")
          |> push_navigate(to: ~p"/game/#{new_game_state.id}")

        {:noreply, socket}

      {:error, reason} ->
        {:noreply, put_flash(socket, :error, "Failed to level up: #{inspect(reason)}")}
    end
  end

  def handle_event("new_game", _params, socket) do
    {:ok, _} = Games.abandon_game(socket.assigns.game.id)

    socket =
      socket
      |> put_flash(:info, "Leaving current game...")
      |> push_navigate(to: ~p"/")

    {:noreply, socket}
  end

  # Note: defp works fine in .heex if it's in the same module
  defp sort_guess(guess_set) do
    guess_set
    |> MapSet.to_list()
    |> Enum.sort(&Choice.compare/2)
  end
end
