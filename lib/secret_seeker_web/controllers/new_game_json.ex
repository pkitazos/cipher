defmodule SecretSeekerWeb.NewGameJSON do
  @doc """
  Starts a new game
  """
  def show(%{game_id: id}) do
    %{id: id, guesses: []}
  end
end
