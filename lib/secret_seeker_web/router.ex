defmodule SecretSeekerWeb.Router do
  use SecretSeekerWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/api", SecretSeekerWeb do
    pipe_through :api

    resources "/games", GameController, only: [:create, :show] do
      post "/guess", GameController, :make_guess
    end
  end
end
