defmodule CipherWeb.GameController do
  use CipherWeb, :controller

  alias Cipher.Games

  action_fallback CipherWeb.FallbackController

  # POST /api/games
  def create(conn, params) do
    with {:ok, difficulty} <- validate_difficulty(params["difficulty"]),
         session_id = params["session_id"] || Ecto.UUID.generate(),
         {:ok, game} <- Games.start_new_game(session_id, difficulty) do
      conn
      |> put_status(:created)
      |> render(:show, game: game)
    end
  end

  # GET /api/games/:id
  def show(conn, %{"id" => id}) do
    case Games.get_running_game(String.to_integer(id)) do
      {:ok, game} ->
        render(conn, :show, game: game)

      {:error, :not_found} ->
        conn
        |> put_status(:not_found)
        |> json(%{error: "Game not found"})
    end
  end

  # POST /api/games/:id/guess
  def make_guess(conn, %{"game_id" => id, "guess" => guess_params}) do
    with {:ok, guess_map} <- Games.parse_guess_input(guess_params),
         game_id = String.to_integer(id),
         {:ok, updated_game} <- Games.make_guess(game_id, guess_map) do
      render(conn, :show, game: updated_game)
    end
  end

  # POST /api/games/:id/level_up
  def level_up(conn, %{"game_id" => id}) do
    with {:ok, new_game_state} <- Games.level_up(id) do
      render(conn, :show, game: new_game_state)
    end
  end

  # --- Private Helpers ---
  defp validate_difficulty("easy"), do: {:ok, :easy}
  defp validate_difficulty("normal"), do: {:ok, :normal}
  defp validate_difficulty("hard"), do: {:ok, :hard}
  defp validate_difficulty(_), do: {:error, :invalid_difficulty}
end
