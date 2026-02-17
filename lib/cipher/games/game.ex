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
    field(:session_id, :string)

    belongs_to(:user, User)

    has_many(:guesses, Guess)

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(game, attrs) do
    game
    |> cast(attrs, [:status, :difficulty, :secret, :user_id, :session_id])
    |> validate_required([:status, :difficulty, :secret])
    |> foreign_key_constraint(:user_id)
    |> validate_has_identifier()
  end

  defp validate_has_identifier(changeset) do
    user_id = get_field(changeset, :user_id)
    session_id = get_field(changeset, :session_id)

    if is_nil(user_id) and is_nil(session_id) do
      add_error(changeset, :base, "must have either a user_id or session_id")
    else
      changeset
    end
  end
end
