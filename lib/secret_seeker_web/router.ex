defmodule SecretSeekerWeb.Router do
  use SecretSeekerWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/api", SecretSeekerWeb do
    pipe_through :api
  end
end
