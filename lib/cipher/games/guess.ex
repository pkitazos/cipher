defmodule Cipher.Games.Guess do
  use Ecto.Schema
  import Ecto.Changeset

  schema "guesses" do
    field(:matches, :integer)
    field(:choices, {:array, Ecto.Enum}, values: Cipher.Games.Choice.values())
    field(:game_id, :id)

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(guess, attrs) do
    guess
    |> cast(attrs, [:matches, :choices])
    |> validate_required([:matches, :choices])
  end
end
