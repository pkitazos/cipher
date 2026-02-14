defmodule CipherWeb.Router do
  use CipherWeb, :router

  pipeline :browser do
    # only accept HTML requests
    plug :accepts, ["html"]
    # loads the session from the cookie
    plug :fetch_session
    # enables flash messages in LiveView
    plug :fetch_live_flash
    # sets the root layout to wrap all pages
    plug :put_root_layout, html: {CipherWeb.Layouts, :root}
    # CSRF protection
    plug :protect_from_forgery
    # security headers
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", CipherWeb do
    pipe_through :browser

    # a bit unclear about what the actions are for since this isn't a REST API
    live "/", DifficultyLive, :index
    live "/game/:game_id", GameLive, :show
  end

  scope "/api", CipherWeb do
    pipe_through :api

    resources "/games", GameController, only: [:create, :show] do
      post "/guess", GameController, :make_guess
      post "/level_up", GameController, :level_up
    end
  end
end
