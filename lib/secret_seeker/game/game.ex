defmodule SecretSeeker.Game do
  alias SecretSeeker.Game.Choice

  @shapes [
    %Choice{kind: :shape, name: :circle, _ord: 0, _kind_ord: 0},
    %Choice{kind: :shape, name: :square, _ord: 1, _kind_ord: 0},
    %Choice{kind: :shape, name: :star, _ord: 2, _kind_ord: 0},
    %Choice{kind: :shape, name: :triangle, _ord: 3, _kind_ord: 0}
  ]

  @colours [
    %Choice{kind: :colour, name: :red, _ord: 0, _kind_ord: 1},
    %Choice{kind: :colour, name: :green, _ord: 1, _kind_ord: 1},
    %Choice{kind: :colour, name: :blue, _ord: 2, _kind_ord: 1},
    %Choice{kind: :colour, name: :yellow, _ord: 3, _kind_ord: 1}
  ]

  @patterns [
    %Choice{kind: :pattern, name: :vertical_stripes, _ord: 0, _kind_ord: 2},
    %Choice{kind: :pattern, name: :horizontal_stripes, _ord: 1, _kind_ord: 2},
    %Choice{kind: :pattern, name: :checkered, _ord: 2, _kind_ord: 2},
    %Choice{kind: :pattern, name: :dotted, _ord: 3, _kind_ord: 2}
  ]

  @directions [
    %Choice{kind: :direction, name: :top, _ord: 0, _kind_ord: 3},
    %Choice{kind: :direction, name: :bottom, _ord: 1, _kind_ord: 3},
    %Choice{kind: :direction, name: :left, _ord: 2, _kind_ord: 3},
    %Choice{kind: :direction, name: :right, _ord: 3, _kind_ord: 3}
  ]

  @choices [shape: @shapes, colour: @colours, pattern: @patterns, direction: @directions]

  # creates one giant map of repr |-> choice
  defp get_items do
    @choices
    |> Enum.map(fn {_kind, options} ->
      options
      |> Enum.map(&{Choice.show(&1), &1})
      |> Enum.into(%{})
    end)
    |> Enum.reduce(&Map.merge/2)
  end

  # the server makes a guess
  def initialise_secret do
    @choices
    |> Enum.map(fn {_kind, options} -> Enum.at(options, :rand.uniform(4) - 1) end)
    |> MapSet.new()
  end

  def convert_guess!(guess) do
    items = get_items()

    guess
    |> String.trim()
    |> String.split(" ")
    |> Enum.map(&Map.fetch!(items, &1))
    |> MapSet.new()
  end

  def convert_guess(guess_string) do
    try do
      guess_set = convert_guess!(guess_string)
      {:ok, guess_set}
    rescue
      _ -> {:error, :invalid_token}
    end
  end

  def calculate_score(guess, secret) do
    4 - (MapSet.difference(secret, guess) |> MapSet.size())
  end

  # ------------------------------------------------------------------------
  # test functions for running game locally

  def start do
    secret =
      @choices
      |> Enum.map(fn elt -> Enum.at(elt.options, :rand.uniform(4) - 1) end)
      |> MapSet.new()

    seeker_guess = MapSet.new()

    game_loop(secret, seeker_guess)
  end

  defp game_loop(secret, seeker_guess) when secret == seeker_guess do
    :correct
  end

  defp game_loop(secret, seeker_guess) do
    score = 4 - (MapSet.difference(secret, seeker_guess) |> MapSet.size())

    IO.puts(score)

    items = get_items()

    next_seeker_guess =
      IO.gets("What is your guess?\n")
      |> String.trim()
      |> String.split(" ")
      |> Enum.map(fn elt -> Map.fetch!(items, elt) end)
      |> MapSet.new()

    game_loop(secret, next_seeker_guess)
  end

  # ------------------------------------------------------------------------
end
