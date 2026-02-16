defmodule Mix.Tasks.Game.New do
  use Mix.Task

  @shortdoc "Creates a new game at the given difficulty"

  def run(args) do
    Application.ensure_all_started(:inets)
    Application.ensure_all_started(:ssl)

    case parse_args(args) do
      {:ok, difficulty} ->
        create_game(difficulty)

      :error ->
        IO.puts(:stderr, "Invalid usage.")
        IO.puts(:stderr, "Usage: mix game.new <easy|normal|hard>")
        IO.puts(:stderr, "Example: mix game.new easy")
    end
  end

  defp parse_args([difficulty]) when difficulty in ~w(easy normal hard), do: {:ok, difficulty}
  defp parse_args(_), do: :error

  defp create_game(difficulty) do
    IO.puts("Creating new game (#{difficulty})...")

    payload = Jason.encode!(%{difficulty: difficulty})

    url = "http://localhost:4000/api/games"
    headers = [{~c"content-type", ~c"application/json"}]
    request = {String.to_charlist(url), headers, ~c"application/json", payload}

    case :httpc.request(:post, request, [], []) do
      {:ok, {{_, 201, _}, _, body}} ->
        response = Jason.decode!(body)

        IO.puts("Game Created!")
        IO.inspect(response, label: "Response")

        IO.puts("\nGame ID: #{response["data"]["id"]}")

      {:ok, {{_, status, _}, _, body}} ->
        IO.puts(:stderr, "Server Error #{status}: #{body}")

      {:error, reason} ->
        IO.puts(:stderr, "Connection Failed: #{inspect(reason)}")
    end
  end
end
