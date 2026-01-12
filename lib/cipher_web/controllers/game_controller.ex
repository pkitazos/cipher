defmodule CipherWeb.GameController do
  use CipherWeb, :controller
  alias Cipher.Game

  action_fallback CipherWeb.FallbackController

  # POST /api/games
  def create(conn, _params) do
    with {:ok, game_id} <- Game.Server.start_game() do
      render(conn, :show, game_id: game_id)
    end
  end

  # GET /api/games/:id
  def show(conn, %{"id" => id}) do
    with {:ok, game} <- Game.Server.join_game(id) do
      render(conn, :show, game: game)
    end
  end

  # POST /api/games/:id/guess
  def make_guess(conn, %{
        "game_id" => id,
        "guess" => %{
          "shape" => shape,
          "colour" => colour,
          "pattern" => pattern,
          "direction" => direction
        }
      }) do
    guess_data = %{shape: shape, colour: colour, pattern: pattern, direction: direction}

    case Game.Server.guess(id, guess_data) do
      :correct -> render(conn, :guess_result, result: :correct)
      {:incorrect, matches} -> render(conn, :guess_result, result: {:incorrect, matches})
      {:error, reason} -> {:error, reason}
    end
  end
end
