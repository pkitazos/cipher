defmodule Cipher.Games.Guess do
  use Ecto.Schema
  import Ecto.Changeset

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
    field(:choices, {:array, Ecto.Enum}, values: @choice_names)
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
