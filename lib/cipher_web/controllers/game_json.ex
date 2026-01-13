defmodule CipherWeb.GameJSON do
  alias Cipher.Game.Choice

  # For creating a game: POST /api/games
  def show(%{game_id: id}) do
    %{id: id, history: []}
  end

  # For getting game state: GET /api/games/:id
  def show(%{game: game}) do
    %{
      id: game.id,
      status: Atom.to_string(game.status),
      history:
        Enum.map(game.guesses, fn {guess_mapset, matches} ->
          %{guesses: Choice.guess_to_map(guess_mapset), matches: matches}
        end)
    }
  end

  # For submitting a guess: POST /api/games/:id/guess
  def guess_result(%{result: {:correct, matches}}) do
    %{result: "correct", matches: matches}
  end

  def guess_result(%{result: {:incorrect, matches}}) do
    %{result: "incorrect", matches: matches}
  end
end
