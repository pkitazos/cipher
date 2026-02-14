defmodule Cipher.Game.GuessSchema do
  use Ecto.Schema
  import Ecto.Changeset

  # This list MUST match the migration ENUM exactly.
  # Ideally this should be imported from Cipher.Game.Choice but Ecto.Enum values
  # must be available at compile time.
  @choice_names [
    :circle,
    :square,
    :star,
    :triangle,
    :red,
    :green,
    :blue,
    :yellow,
    :vertical_stripes,
    :horizontal_stripes,
    :checkered,
    :dotted,
    :top,
    :bottom,
    :left,
    :right,
    :tiny,
    :small,
    :medium,
    :large
  ]

  schema "guesses" do
    field(:matches, :integer)
    # Stored as an array of the ENUM type in Postgres, mapped to atoms here.
    field(:choices, {:array, Ecto.Enum}, values: @choice_names)

    belongs_to(:game, Cipher.Game.Schema)

    timestamps()
  end

  def changeset(guess, attrs) do
    guess
    |> cast(attrs, [:matches, :choices, :game_id])
    |> validate_required([:matches, :choices, :game_id])
  end
end
