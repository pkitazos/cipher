defmodule CipherWeb.Router do
  use CipherWeb, :router

  import CipherWeb.UserAuth

  pipeline :browser do
    # only accept HTML requests
    plug :accepts, ["html"]
    # loads the session from the cookie
    plug :fetch_session
    plug CipherWeb.Plugs.GuestSession
    # enables flash messages in LiveView
    plug :fetch_live_flash
    # sets the root layout to wrap all pages
    plug :put_root_layout, html: {CipherWeb.Layouts, :root}
    # CSRF protection
    plug :protect_from_forgery
    # security headers
    plug :put_secure_browser_headers
    plug :fetch_current_scope_for_user
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", CipherWeb do
    pipe_through :browser

    live_session :default,
      on_mount: [{CipherWeb.UserAuth, :mount_current_scope}] do
      live "/", DifficultyLive, :index
      live "/game/:game_id", GameLive, :show
    end
  end

  scope "/api", CipherWeb do
    pipe_through :api

    resources "/games", GameController, only: [:create, :show] do
      post "/guess", GameController, :make_guess
      post "/level_up", GameController, :level_up
    end
  end

  ## Authentication routes

  scope "/", CipherWeb do
    pipe_through [:browser, :require_authenticated_user]

    live_session :require_authenticated_user,
      on_mount: [{CipherWeb.UserAuth, :require_authenticated}] do
      live "/users/settings", UserLive.Settings, :edit
      live "/users/settings/confirm-email/:token", UserLive.Settings, :confirm_email
    end

    post "/users/update-password", UserSessionController, :update_password
  end

  scope "/", CipherWeb do
    pipe_through [:browser]

    live_session :current_user,
      on_mount: [{CipherWeb.UserAuth, :mount_current_scope}] do
      live "/users/register", UserLive.Registration, :new
      live "/users/log-in", UserLive.Login, :new
      live "/users/log-in/:token", UserLive.Confirmation, :new
    end

    post "/users/log-in", UserSessionController, :create
    delete "/users/log-out", UserSessionController, :delete
  end

  if Application.compile_env(:cipher, :dev_routes) do
    scope "/dev" do
      pipe_through :browser
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
