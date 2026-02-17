defmodule Cipher.Game do
  @moduledoc """
  The pure domain entity representing a running game.
  Decoupled from the database schema.
  """

  alias Cipher.Guess
  alias Cipher.Games.Choice
  alias Cipher.Games.Game, as: DBGame

  defstruct [
    :id,
    :user_id,
    :session_id,
    :difficulty,
    :status,
    :secret,
    :guesses,
    :num_guesses,
    :last_matches
  ]

  @type difficulty :: :easy | :normal | :hard
  @type status :: :won | :active | :abandoned
  @type guess_entry :: {MapSet.t(Choice.t()), integer()}

  @type t :: %__MODULE__{
          id: integer(),
          user_id: integer(),
          session_id: String.t() | nil,
          difficulty: difficulty(),
          status: status(),
          secret: MapSet.t(Choice.t()),
          guesses: list(Guess.t()),
          num_guesses: integer(),
          last_matches: integer() | nil
        }

  def client_view(%__MODULE__{} = game) do
    %{game | secret: MapSet.new()}
  end

  @doc """
  Converts a Database Schema struct into a Domain Entity.
  Enforces that the 'guesses' association MUST be loaded in the db_game.
  """
  def new(%DBGame{guesses: guesses} = db_game) when is_list(guesses) do
    # sort descending by inserted_at so the latest guess is first
    domain_guesses =
      guesses
      |> Enum.sort_by(& &1.inserted_at, {:desc, Date})
      |> Enum.map(&Guess.new/1)

    # List<Atom> -> MapSet<%Choice{}>
    domain_secret =
      db_game.secret
      |> Enum.map(&Choice.from_name/1)
      |> MapSet.new()

    last_matches_val =
      case domain_guesses do
        [latest | _] -> latest.matches
        [] -> nil
      end

    %__MODULE__{
      id: db_game.id,
      user_id: db_game.user_id,
      session_id: db_game.session_id,
      difficulty: db_game.difficulty,
      status: db_game.status,
      secret: domain_secret,
      guesses: domain_guesses,
      num_guesses: db_game.num_guesses || length(domain_guesses),
      last_matches: last_matches_val
    }
  end
end
