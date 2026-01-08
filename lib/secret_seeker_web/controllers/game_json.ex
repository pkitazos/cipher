defmodule SecretSeekerWeb.GameJSON do
  @doc """
  Joins a game
  """
  def show(%{game: game}) do
    %{id: game.id, guesses: game.guesses}
  end
end
