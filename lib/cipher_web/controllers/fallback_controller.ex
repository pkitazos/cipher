defmodule CipherWeb.FallbackController do
  use CipherWeb, :controller

  def call(conn, {:error, :not_found}) do
    conn
    |> put_status(:not_found)
    |> json(%{error: "Resource not found"})
  end

  def call(conn, {:error, :invalid_params}) do
    conn
    |> put_status(:bad_request)
    |> json(%{error: "Invalid parameters"})
  end

  def call(conn, {:error, :game_not_found}) do
    conn
    |> put_status(:not_found)
    |> json(%{error: "Game not found"})
  end

  def call(conn, {:error, {:invalid_choice, kind, value}}) do
    conn
    |> put_status(:bad_request)
    |> json(%{error: "Invalid #{kind}", value: value})
  end

  def call(conn, {:error, {:missing_field, kind}}) do
    conn
    |> put_status(:bad_request)
    |> json(%{error: "Missing required field: #{kind}"})
  end

  def call(conn, {:error, {:invalid_format, kind}}) do
    conn
    |> put_status(:bad_request)
    |> json(%{error: "Invalid format for field: #{kind}"})
  end

  # Catch-all for unexpected errors
  def call(conn, {:error, _reason}) do
    conn
    |> put_status(:internal_server_error)
    |> json(%{error: "Something went wrong"})
  end
end
