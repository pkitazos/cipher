defmodule SecretSeekerWeb.NewGameController do
  use SecretSeekerWeb, :controller
  alias SecretSeeker.Game

  action_fallback SecretSeekerWeb.FallbackController

  def new_game(conn, _params) do
    with {:ok, game_id} <- Game.Server.start_game() do
      render(conn, :show, game_id: game_id)
    end
  end
end
