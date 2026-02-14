defmodule Cipher.Game do
  @moduledoc """
  The pure domain entity representing a running game.
  Decoupled from the database schema.
  """

  defstruct [
    :id,
    :user_id,
    :difficulty,
    :status,
    :secret,
    :guesses,
    :last_matches
  ]

  @type difficulty :: :easy | :normal | :hard
  @type status :: :won | :active | :abandoned
  @type guess_entry :: {MapSet.t(Choice.t()), integer()}

  @type t :: %__MODULE__{
          id: integer(),
          user_id: integer(),
          difficulty: difficulty(),
          status: status(),
          secret: MapSet.t(Choice.t()),
          guesses: list(guess_entry()),
          last_matches: integer() | nil
        }

  alias Cipher.Games.Game, as: DBGame

  @doc """
  Converts a Database Schema struct into a Domain Entity.
  """
  def from_db(%DBGame{} = db_game) do
    %__MODULE__{
      id: db_game.id,
      user_id: db_game.user_id,
      difficulty: db_game.difficulty,
      status: db_game.status,
      secret: MapSet.new(db_game.secret),
      guesses: [],
      last_matches: nil
    }
  end

  def client_view(%__MODULE__{} = game) do
    %{game | secret: MapSet.new()}
  end

  alias Cipher.Games.Game, as: DBGame
  alias Cipher.Games.Guess, as: DBGuess

  def new(%DBGame{} = db_game) do
    guesses_runtime =
      if Ecto.assoc_loaded?(db_game.guesses) do
        db_game.guesses
        |> Enum.sort_by(& &1.inserted_at, {:desc, Date})
        |> Enum.map(fn guess ->
          parsed_choices =
            guess.choices
            |> Enum.map(&to_atom/1)
            |> Enum.map(&Cipher.Games.Choice.from_name/1)
            |> MapSet.new()

          {parsed_choices, guess.matches}
        end)
      else
        []
      end

    last_matches =
      case guesses_runtime do
        [{_guess, matches} | _] -> matches
        [] -> nil
      end

    secret =
      db_game.secret
      |> Enum.map(&Cipher.Games.Choice.from_name/1)
      |> MapSet.new()

    %__MODULE__{
      id: db_game.id,
      user_id: db_game.user_id,
      difficulty: db_game.difficulty,
      status: db_game.status,
      secret: secret,
      guesses: guesses_runtime,
      last_matches: last_matches
    }
  end

  defp convert_guess(%DBGuess{} = guess) do
    parsed_choices =
      guess.choices
      |> Enum.map(&to_atom/1)
      |> MapSet.new()

    {parsed_choices, guess.matches}
  end

  defp to_atom(v) when is_atom(v), do: v
  defp to_atom(v) when is_binary(v), do: String.to_existing_atom(v)
end
