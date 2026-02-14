defmodule Cipher.Game.Schema do
  use Ecto.Schema
  import Ecto.Changeset

  alias Cipher.Game.GuessSchema
  alias Cipher.Accounts.User

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

  schema "games" do
    field(:status, Ecto.Enum, values: [:active, :won, :abandoned, :expired])
    field(:difficulty, Ecto.Enum, values: [:easy, :normal, :hard])

    # Stores the secret as an array of atoms (mapped to Postgres ENUM array)
    field(:secret, {:array, Ecto.Enum}, values: @choice_names, type: :string)
    # field(:secret, {:array, Ecto.Enum}, values: @choice_names)

    belongs_to(:user, User)
    has_many(:guesses, GuessSchema, foreign_key: :game_id)

    timestamps()
  end

  def changeset(game, attrs) do
    game
    |> cast(attrs, [:status, :difficulty, :secret, :user_id])
    |> validate_required([:status, :difficulty, :secret])
  end
end
