defmodule CipherWeb.GameController do
  use CipherWeb, :controller
  alias Cipher.Game

  action_fallback CipherWeb.FallbackController

  # POST /api/games
  def create(conn, params) do
    difficulty = parse_difficulty(params["difficulty"])

    with {:ok, game_id} <- Game.Server.start_game(difficulty) do
      render(conn, :show, game_id: game_id)
    end
  end

  defp parse_difficulty(nil), do: :normal

  defp parse_difficulty(difficulty) when is_binary(difficulty) do
    atom = String.to_existing_atom(difficulty)
    if atom in [:easy, :normal, :hard], do: atom, else: :normal
  rescue
    ArgumentError -> :normal
  end

  defp parse_difficulty(_), do: :normal

  # GET /api/games/:id
  def show(conn, %{"id" => id}) do
    with {:ok, game} <- Game.Server.join_game(id) do
      render(conn, :show, game: game)
    end
  end

  # POST /api/games/:id/guess
  def make_guess(conn, %{"game_id" => id, "guess" => guess_params}) do
    guess_data = %{
      shape: guess_params["shape"],
      colour: guess_params["colour"],
      pattern: guess_params["pattern"],
      direction: guess_params["direction"],
      size: guess_params["size"]
    }

    case Game.Server.guess(id, guess_data) do
      {:correct, matches} -> render(conn, :guess_result, result: {:correct, matches})
      {:incorrect, matches} -> render(conn, :guess_result, result: {:incorrect, matches})
      {:error, reason} -> {:error, reason}
    end
  end

  # POST /api/games/:id/reset
  def reset(conn, %{"game_id" => id}) do
    with {:ok, game} <- Game.Server.reset_game(id) do
      render(conn, :show, game: game)
    end
  end

  # POST /api/games/:id/level_up
  def level_up(conn, %{"game_id" => id}) do
    with {:ok, new_game_id} <- Game.Server.level_up(id) do
      render(conn, :show, game_id: new_game_id)
    end
  end
end
