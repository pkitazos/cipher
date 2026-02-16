defmodule Mix.Tasks.Game.Guess do
  use Mix.Task

  @shortdoc "Submits a guess to a running game"

  def run(args) do
    Application.ensure_all_started(:inets)
    Application.ensure_all_started(:ssl)

    case parse_args(args) do
      {id, choices} ->
        submit_guess(id, choices)

      :error ->
        IO.puts(:stderr, "Invalid usage.")
        IO.puts(:stderr, "Usage: mix game.guess <game_id> <choice1> <choice2> ...")
        IO.puts(:stderr, "Example: mix game.guess 16 red circle")
    end
  end

  defp parse_args([id | choices]) do
    {id, choices}
  end

  defp parse_args(_), do: :error

  defp submit_guess(game_id, choices) do
    guess_map =
      choices
      |> Enum.reduce(%{}, fn choice, acc ->
        kind = identify_kind(choice)
        if kind, do: Map.put(acc, kind, choice), else: acc
      end)

    payload = Jason.encode!(%{guess: guess_map})

    IO.puts("[Game ##{game_id}] making guess...")

    url = "http://localhost:4000/api/games/#{game_id}/guess"
    headers = [{~c"content-type", ~c"application/json"}]
    request = {String.to_charlist(url), headers, ~c"application/json", payload}

    case :httpc.request(:post, request, [], []) do
      {:ok, {{_, 200, _}, _, body}} ->
        body
        |> Jason.decode!()
        |> IO.inspect(label: "Success")

      {:ok, {{_, status, _}, _, body}} ->
        IO.puts(:stderr, "Error #{status}: #{body}")

      {:error, reason} ->
        IO.puts(:stderr, "Connection Failed: #{inspect(reason)}")
    end
  end

  defp identify_kind(val) when val in ~w(circle square star triangle), do: "shape"
  defp identify_kind(val) when val in ~w(red green blue yellow), do: "colour"

  defp identify_kind(val) when val in ~w(vertical_stripes horizontal_stripes checkered dotted),
    do: "pattern"

  defp identify_kind(val) when val in ~w(top bottom left right), do: "direction"
  defp identify_kind(val) when val in ~w(tiny small medium large), do: "size"
  defp identify_kind(_), do: nil
end
