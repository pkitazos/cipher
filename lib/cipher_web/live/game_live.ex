defmodule CipherWeb.GameLive do
  require Logger
  use CipherWeb, :live_view

  alias CipherWeb.Layouts
  alias CipherWeb.ChoiceComponents

  alias Cipher.Games
  alias Cipher.Guess
  alias Cipher.Games.{Choice, Logic}

  def mount(%{"game_id" => id}, session, socket) do
    case Games.get_running_game(String.to_integer(id)) do
      {:ok, game} ->
        Logger.debug("[game status is] #{game.status}")
        caller = caller_from_socket(socket, session)
        owner? = is_owner?(caller, game)
        {:ok, assign(socket, game: game, guess: %{}, caller: caller, owner?: owner?)}

      {:error, :not_found} ->
        {:ok,
         socket
         |> put_flash(:error, "Game not found")
         |> push_navigate(to: ~p"/")}
    end
  end

  def handle_event("toggle_choice", %{"kind" => kind_str, "choice" => choice_name_str}, socket) do
    kind = String.to_existing_atom(kind_str)

    choice =
      choice_name_str
      |> String.to_existing_atom()
      |> Choice.from_name()

    updated_guess =
      if socket.assigns.guess[kind] && socket.assigns.guess[kind].name == choice.name do
        Map.delete(socket.assigns.guess, kind)
      else
        Map.put(socket.assigns.guess, kind, choice)
      end

    {:noreply, assign(socket, guess: updated_guess)}
  end

  def handle_event(
        "make_guess",
        _params,
        %{assigns: %{guess: guess_map, game: game, caller: caller}} = socket
      ) do
    # convert UI Map -> domain Guess DTO
    guess = Guess.new_from_game(game.id, guess_map)

    case Games.make_guess(caller, game.id, guess) do
      {:ok, updated_state} ->
        {:noreply, assign(socket, game: updated_state, guess: %{})}

      {:error, :unauthorized} ->
        {:noreply,
         socket
         |> put_flash(:error, "You are not the owner of this game.")
         |> push_navigate(to: ~p"/")}

      {:error, reason} ->
        {:noreply, put_flash(socket, :error, "Guess failed: #{inspect(reason)}")}
    end
  end

  def handle_event("level_up", _params, %{assigns: %{game: game, caller: caller}} = socket) do
    case Games.level_up(caller, game.id) do
      {:ok, new_game_state} ->
        {:noreply, push_navigate(socket, to: ~p"/game/#{new_game_state.id}")}

      {:error, :unauthorized} ->
        {:noreply,
         socket
         |> put_flash(:error, "You are not the owner of this game.")
         |> push_navigate(to: ~p"/")}

      {:error, reason} ->
        {:noreply, put_flash(socket, :error, "Failed to level up: #{inspect(reason)}")}
    end
  end

  def handle_event("new_game", _params, %{assigns: %{game: game, caller: caller}} = socket) do
    case Games.abandon_game(caller, game.id) do
      {:ok, _} ->
        {:noreply, push_navigate(socket, to: ~p"/")}

      {:error, :unauthorized} ->
        {:noreply,
         socket
         |> put_flash(:error, "You are not the owner of this game.")
         |> push_navigate(to: ~p"/")}

      {:error, _} ->
        {:noreply, push_navigate(socket, to: ~p"/")}
    end
  end

  defp caller_from_socket(socket, session) do
    case socket.assigns[:current_scope] do
      %{user: user} -> user
      _ -> session["guest_session_id"]
    end
  end

  defp is_owner?(caller, game) do
    case caller do
      %{id: user_id} -> game.user_id == user_id
      session_id when is_binary(session_id) -> game.session_id == session_id
      _ -> false
    end
  end

  # Note: defp works fine in .heex if it's in the same module
  defp sort_guess(guess_set) do
    guess_set
    |> MapSet.to_list()
    |> Enum.sort(&Choice.compare/2)
  end
end
