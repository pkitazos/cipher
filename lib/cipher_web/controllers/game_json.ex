defmodule CipherWeb.GameJSON do
  alias Cipher.Game.Choice

  # For creating a game: POST /api/games
  def show(%{game_id: id}) do
    %{id: id, guesses: []}
  end

  # For getting game state: GET /api/games/:id
  def show(%{game: game}) do
    %{
      id: game.id,
      status: Atom.to_string(game.status),
      guesses: Enum.map(game.guesses, &Choice.guess_to_map/1)
    }
  end

  # For submitting a guess: POST /api/games/:id/guess
  def guess_result(%{result: :correct}) do
    %{result: "correct", message: "You won!"}
  end

  def guess_result(%{result: {:incorrect, matches}}) do
    %{result: "incorrect", matches: matches}
  end
end
