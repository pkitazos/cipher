defmodule Cipher.Game do
  require Logger
  alias Cipher.Game.Choice

  @type difficulty :: :easy | :normal | :hard
  @type guess_map :: %{
          optional(:shape) => String.t(),
          optional(:colour) => String.t(),
          optional(:pattern) => String.t(),
          optional(:direction) => String.t(),
          optional(:size) => String.t()
        }

  @shapes [
    %Choice{kind: :shape, name: :circle},
    %Choice{kind: :shape, name: :square},
    %Choice{kind: :shape, name: :star},
    %Choice{kind: :shape, name: :triangle}
  ]

  @colours [
    %Choice{kind: :colour, name: :red},
    %Choice{kind: :colour, name: :green},
    %Choice{kind: :colour, name: :blue},
    %Choice{kind: :colour, name: :yellow}
  ]

  @patterns [
    %Choice{kind: :pattern, name: :vertical_stripes},
    %Choice{kind: :pattern, name: :horizontal_stripes},
    %Choice{kind: :pattern, name: :checkered},
    %Choice{kind: :pattern, name: :dotted}
  ]

  @directions [
    %Choice{kind: :direction, name: :top},
    %Choice{kind: :direction, name: :bottom},
    %Choice{kind: :direction, name: :left},
    %Choice{kind: :direction, name: :right}
  ]

  @sizes [
    %Choice{kind: :size, name: :tiny},
    %Choice{kind: :size, name: :small},
    %Choice{kind: :size, name: :medium},
    %Choice{kind: :size, name: :large}
  ]

  @all_choices [
    shape: @shapes,
    colour: @colours,
    pattern: @patterns,
    direction: @directions,
    size: @sizes
  ]

  @difficulty_categories %{
    easy: [:shape, :colour, :pattern],
    normal: [:shape, :colour, :pattern, :direction],
    hard: [:shape, :colour, :pattern, :direction, :size]
  }

  @valid_difficulties Map.keys(@difficulty_categories)

  @spec next_difficulty(difficulty()) :: {:ok, difficulty()} | {:error, :max_difficulty}
  @spec next_difficulty(any()) :: {:error, :invalid_difficulty}
  def next_difficulty(:easy), do: {:ok, :normal}
  def next_difficulty(:normal), do: {:ok, :hard}
  def next_difficulty(:hard), do: {:error, :max_difficulty}
  def next_difficulty(_), do: {:error, :invalid_difficulty}

  @spec get_items_from_name() :: %{atom() => Choice.t()}
  defp get_items_from_name do
    @all_choices
    |> Enum.map(fn {_kind, options} ->
      options
      |> Enum.map(&{&1.name, &1})
      |> Enum.into(%{})
    end)
    |> Enum.reduce(&Map.merge/2)
  end

  @spec get_choices_by_kind(atom()) :: %{atom() => Choice.t()}
  def get_choices_by_kind(kind) do
    @all_choices
    |> Keyword.get(kind)
    |> Enum.map(&{&1.name, &1})
    |> Enum.into(%{})
  end

  @spec get_active_categories(difficulty()) :: [atom()]
  def get_active_categories(difficulty) when difficulty in @valid_difficulties do
    Map.fetch!(@difficulty_categories, difficulty)
  end

  @spec get_choices_for_category(atom()) :: [Choice.t()] | nil
  def get_choices_for_category(category) do
    Keyword.get(@all_choices, category)
  end

  @spec validate_choice(atom(), String.t()) ::
          {:ok, Choice.t()} | {:error, {:invalid_choice, atom(), String.t()}}
  @spec validate_choice(atom(), nil) :: {:error, {:missing_field, atom()}}
  @spec validate_choice(atom(), any()) :: {:error, {:invalid_format, atom()}}
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

  @spec initialise_secret(difficulty()) :: MapSet.t(Choice.t())
  def initialise_secret(difficulty \\ :normal)

  def initialise_secret(difficulty) when difficulty in @valid_difficulties do
    active_categories = get_active_categories(difficulty)

    active_categories
    |> Enum.map(fn category ->
      options = Keyword.fetch!(@all_choices, category)
      Enum.at(options, :rand.uniform(length(options)) - 1)
    end)
    |> MapSet.new()
  end

  @spec convert_guess!(guess_map()) :: MapSet.t(Choice.t())
  def convert_guess!(guess) do
    items = get_items_from_name()

    shape = Map.fetch!(items, String.to_atom(guess.shape))
    colour = Map.fetch!(items, String.to_atom(guess.colour))
    pattern = Map.fetch!(items, String.to_atom(guess.pattern))
    direction = Map.fetch!(items, String.to_atom(guess.direction))

    MapSet.new([shape, colour, pattern, direction])
  end

  @spec convert_guess_from_choices(%{atom() => Choice.t()}, difficulty()) ::
          {:ok, MapSet.t(Choice.t())} | {:error, {:missing_field, atom()}}
  def convert_guess_from_choices(choice_map, difficulty)
      when difficulty in @valid_difficulties do
    active_categories = get_active_categories(difficulty)

    case Enum.find(active_categories, fn cat -> !Map.has_key?(choice_map, cat) end) do
      nil ->
        choices = Enum.map(active_categories, &Map.fetch!(choice_map, &1))
        {:ok, MapSet.new(choices)}

      missing_category ->
        {:error, {:missing_field, missing_category}}
    end
  end

  @spec convert_guess_from_strings(guess_map(), difficulty()) ::
          {:ok, MapSet.t(Choice.t())}
          | {:error, {:invalid_choice, atom(), String.t()}}
          | {:error, {:missing_field, atom()}}
          | {:error, {:invalid_format, atom()}}
  def convert_guess_from_strings(guess, difficulty \\ :normal)

  def convert_guess_from_strings(guess, difficulty) when difficulty in @valid_difficulties do
    active_categories = get_active_categories(difficulty)

    active_categories
    |> Enum.reduce_while(
      {:ok, []},
      fn category, {:ok, acc} ->
        field_value = Map.get(guess, category)

        case validate_choice(category, field_value) do
          {:ok, choice} -> {:cont, {:ok, [choice | acc]}}
          {:error, _} = error -> {:halt, error}
        end
      end
    )
    |> case do
      {:ok, choices} -> {:ok, MapSet.new(choices)}
      error -> error
    end
  end

  @doc """
  Deprecated: Use convert_guess_from_strings/2 or convert_guess_from_choices/2 instead.
  """
  @spec convert_guess(guess_map(), difficulty()) ::
          {:ok, MapSet.t(Choice.t())}
          | {:error, {:invalid_choice, atom(), String.t()}}
          | {:error, {:missing_field, atom()}}
          | {:error, {:invalid_format, atom()}}
  def convert_guess(guess, difficulty \\ :normal) do
    convert_guess_from_strings(guess, difficulty)
  end

  @spec calculate_matches(MapSet.t(Choice.t()), MapSet.t(Choice.t())) :: non_neg_integer()
  def calculate_matches(guess, secret) do
    MapSet.size(secret) - (MapSet.difference(secret, guess) |> MapSet.size())
  end
end
