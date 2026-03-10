defmodule CipherWeb.UserSessionController do
  use CipherWeb, :controller

  alias Cipher.Accounts
  alias CipherWeb.UserAuth

  # magic link login
  def create(conn, %{"user" => %{"token" => token} = user_params}) do
    case Accounts.login_user_by_magic_link(token) do
      {:ok, {user, tokens_to_disconnect}} ->
        UserAuth.disconnect_sessions(tokens_to_disconnect)

        conn
        |> UserAuth.log_in_user(user, user_params)

      _ ->
        conn
        |> put_flash(:error, "The link is invalid or it has expired.")
        |> redirect(to: ~p"/users/log-in")
    end
  end

  def delete(conn, _params) do
    UserAuth.log_out_user(conn)
  end
end
