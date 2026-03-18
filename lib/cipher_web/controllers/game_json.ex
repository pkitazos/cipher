defmodule CipherWeb.GameJSON do
  alias Cipher.Game
  alias Cipher.Games.Choice
  alias Cipher.Guess

  @doc """
  Renders a single game.
  """
  def show(%{game: game}) do
    %{data: data(game)}
  end

  defp data(%Game{} = game) do
    %{
      id: game.id,
      difficulty: Atom.to_string(game.difficulty),
      status: Atom.to_string(game.status),
      user_id: game.user_id,
      history: Enum.map(game.guesses, &transform_guess/1),
      last_matches: game.last_matches
    }
  end

  # Convert Guess struct to JSON representation
  defp transform_guess(%Guess{choices: guess_mapset, matches: matches}) do
    %{
      matches: matches,
      choices:
        guess_mapset
        |> Choice.guess_to_map()
        |> Enum.into(%{}, fn {k, v} -> {k, Atom.to_string(v)} end)
    }
  end
end
