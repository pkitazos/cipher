defmodule SecretSeekerWeb.Router do
  use SecretSeekerWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/api", SecretSeekerWeb do
    pipe_through :api

    get "/", NewGameController, :new_game
    get "/game/:id", GameController, :join_game
  end
end
