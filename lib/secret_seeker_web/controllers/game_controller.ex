defmodule SecretSeekerWeb.GameController do
  use SecretSeekerWeb, :controller
  alias SecretSeeker.Game

  action_fallback SecretSeekerWeb.FallbackController

  def join_game(conn, %{"id" => id}) do
    with {:ok, game} <- Game.Server.join_game(id) do
      render(conn, :show, game: game)
    end
  end
end
