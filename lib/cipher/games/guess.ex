defmodule Cipher.Games.Guess do
  use Ecto.Schema
  import Ecto.Changeset
  alias Cipher.Games.Game

  schema "guesses" do
    field(:matches, :integer)
    field(:choices, {:array, Ecto.Enum}, values: Cipher.Games.Choice.values())
    field(:game_id, :id)

    belongs_to(:game, Game, define_field: false)

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(guess, attrs) do
    guess
    |> cast(attrs, [:matches, :choices, :game_id])
    |> validate_required([:matches, :choices, :game_id])
  end
end
