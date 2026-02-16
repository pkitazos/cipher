defmodule Cipher.Games.Game do
  use Ecto.Schema
  import Ecto.Changeset

  alias Cipher.Accounts.User
  alias Cipher.Games.Guess

  schema "games" do
    field(:status, Ecto.Enum, values: [:won, :active, :abandoned], default: :active)
    field(:difficulty, Ecto.Enum, values: [:easy, :normal, :hard])
    field(:secret, {:array, Ecto.Enum}, values: Cipher.Games.Choice.values())
    field(:num_guesses, :integer, virtual: true)

    belongs_to(:user, User)

    has_many(:guesses, Guess)

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(game, attrs) do
    game
    # We add :user_id to the cast list so it can be saved
    |> cast(attrs, [:status, :difficulty, :secret, :user_id])
    |> validate_required([:status, :difficulty, :secret])
    |> foreign_key_constraint(:user_id)
  end
end
