defmodule Cipher.Games.Logic do
  @moduledoc """
  Pure domain logic for the game.
  Responsible for Game Rules, Secret Generation, and Match Calculation.
  """
  alias Cipher.Games.Choice

  @type difficulty :: :easy | :normal | :hard

  # --- Configuration ---

  @difficulty_categories %{
    easy: [:shape, :colour, :pattern],
    normal: [:shape, :colour, :pattern, :direction],
    hard: [:shape, :colour, :pattern, :direction, :size]
  }

  @valid_difficulties Map.keys(@difficulty_categories)

  # --- Game Rules (Queries) ---

  @doc "Returns the list of active categories (e.g., [:shape, :colour]) for a difficulty."
  def get_active_categories(difficulty) when difficulty in @valid_difficulties do
    Map.fetch!(@difficulty_categories, difficulty)
  end

  @doc """
  Returns all valid Choice structs for a given category.
  Delegates to Choice module to get atoms, then hydrates to Structs
  """
  def get_choices_for_category(category) do
    category
    |> Choice.options()
    |> Enum.map(&Choice.from_name/1)
  end

  @doc "Determines the next difficulty level."
  def next_difficulty(:easy), do: {:ok, :normal}
  def next_difficulty(:normal), do: {:ok, :hard}
  def next_difficulty(:hard), do: {:error, :max_difficulty}
  def next_difficulty(_), do: {:error, :invalid_difficulty}

  # --- Core Actions ---

  @doc """
  Generates a random secret based on difficulty.
  Returns a MapSet of %Choice{} structs.
  """
  @spec initialise_secret(difficulty()) :: MapSet.t(Choice.t())
  def initialise_secret(difficulty) do
    difficulty
    |> get_active_categories()
    |> Enum.map(fn category ->
      # pick one random struct from the available options for this category
      category
      |> get_choices_for_category()
      |> Enum.random()
    end)
    |> MapSet.new()
  end

  @doc """
  Calculates the number of exact matches between a guess and the secret.
  Works with MapSets of %Choice{} structs.
  """
  @spec calculate_matches(MapSet.t(Choice.t()), MapSet.t(Choice.t())) :: integer()
  def calculate_matches(guess, secret) do
    MapSet.intersection(guess, secret) |> MapSet.size()
  end

  @doc """
  Validates if a guess is complete and valid for the current difficulty.
  """
  @spec validate_guess(MapSet.t(Choice.t()), difficulty()) ::
          :ok | {:error, :incomplete_guess} | {:error, :invalid_items}
  def validate_guess(guess_set, difficulty) do
    required_categories =
      difficulty
      |> get_active_categories()
      |> MapSet.new()

    guess_kinds =
      guess_set
      |> Enum.map(& &1.kind)
      |> MapSet.new()

    cond do
      MapSet.size(guess_set) != MapSet.size(required_categories) -> {:error, :incomplete_guess}
      guess_kinds != required_categories -> {:error, :invalid_items}
      true -> :ok
    end
  end
end
