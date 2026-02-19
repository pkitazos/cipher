defmodule CipherWeb.PageController do
  use CipherWeb, :controller

  def not_found(conn, _params) do
    conn
    |> put_status(:not_found)
    |> render(:not_found)
  end
end
