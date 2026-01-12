defmodule CipherWeb.Router do
  use CipherWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/api", CipherWeb do
    pipe_through :api

    resources "/games", GameController, only: [:create, :show] do
      post "/guess", GameController, :make_guess
      post "/reset", GameController, :reset
    end
  end
end
