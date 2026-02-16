defmodule CipherWeb.FallbackController do
  use CipherWeb, :controller

  def call(conn, {:error, :not_found}) do
    conn
    |> put_status(:not_found)
    |> json(%{error: "Resource not found"})
  end

  def call(conn, {:error, :game_not_found}) do
    conn
    |> put_status(:not_found)
    |> json(%{error: "Game not found"})
  end

  def call(conn, {:error, {:game_not_active, :won}}) do
    conn
    |> put_status(:conflict)
    |> json(%{error: "Game already completed", status: "won"})
  end

  def call(conn, {:error, {:game_not_active, :abandoned}}) do
    conn
    |> put_status(:gone)
    |> json(%{error: "Game was abandoned", status: "abandoned"})
  end

  def call(conn, {:error, :invalid_params}) do
    conn
    |> put_status(:bad_request)
    |> json(%{error: "Invalid parameters"})
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

  def call(conn, {:error, :max_difficulty}) do
    conn
    |> put_status(:bad_request)
    |> json(%{error: "Already at maximum difficulty"})
  end

  def call(conn, {:error, :invalid_parameters}) do
    conn
    |> put_status(:bad_request)
    |> json(%{error: "Invalid parameter format. Check that your choices match the known list."})
  end

  def call(conn, {:error, :invalid_difficulty}) do
    conn
    |> put_status(:bad_request)
    |> json(%{error: "Difficulty must be one of: easy, normal, hard"})
  end

  def call(conn, {:error, reason})
      when reason in [:incomplete_guess, :invalid_items, :too_many_items] do
    conn
    |> put_status(:unprocessable_entity)
    |> json(%{error: "Guess rejected", reason: Atom.to_string(reason)})
  end

  # Catch-all for unexpected errors
  def call(conn, {:error, _reason}) do
    conn
    |> put_status(:internal_server_error)
    |> json(%{error: "Something went wrong"})
  end
end
