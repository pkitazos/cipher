defmodule Cipher.Game do
  require Logger
  alias Cipher.Game.Choice

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

  defp get_items_from_name do
    @choices
    |> Enum.map(fn {_kind, options} ->
      options
      |> Enum.map(&{&1.name, &1})
      |> Enum.into(%{})
    end)
    |> Enum.reduce(&Map.merge/2)
  end

  defp get_choices_by_kind(kind) do
    @choices
    |> Keyword.get(kind)
    |> Enum.map(&{&1.name, &1})
    |> Enum.into(%{})
  end

  defp validate_choice(kind, value) when is_binary(value) do
    choices = get_choices_by_kind(kind)
    atom_value = String.to_atom(value)

    case Map.fetch(choices, atom_value) do
      {:ok, choice} -> {:ok, choice}
      :error -> {:error, {:invalid_choice, kind, value}}
    end
  end

  defp validate_choice(kind, nil), do: {:error, {:missing_field, kind}}
  defp validate_choice(kind, _), do: {:error, {:invalid_format, kind}}

  def initialise_secret do
    @choices
    |> Enum.map(fn {_kind, options} -> Enum.at(options, :rand.uniform(4) - 1) end)
    |> MapSet.new()
  end

  def convert_guess!(guess) do
    items = get_items_from_name()

    shape = Map.fetch!(items, String.to_atom(guess.shape))
    colour = Map.fetch!(items, String.to_atom(guess.colour))
    pattern = Map.fetch!(items, String.to_atom(guess.pattern))
    direction = Map.fetch!(items, String.to_atom(guess.direction))

    MapSet.new([shape, colour, pattern, direction])
  end

  def convert_guess(guess) do
    with {:ok, shape} <- validate_choice(:shape, guess.shape),
         {:ok, colour} <- validate_choice(:colour, guess.colour),
         {:ok, pattern} <- validate_choice(:pattern, guess.pattern),
         {:ok, direction} <- validate_choice(:direction, guess.direction) do
      {:ok, MapSet.new([shape, colour, pattern, direction])}
    end
  end

  def calculate_matches(guess, secret) do
    4 - (MapSet.difference(secret, guess) |> MapSet.size())
  end
end
