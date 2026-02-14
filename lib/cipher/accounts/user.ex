defmodule Cipher.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset

  schema "users" do
    field(:email, :string)
    field(:username, :string)
    field(:provider, :string)
    field(:uid, :string)

    timestamps()
  end

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:email, :username, :provider, :uid])
    |> validate_required([:username])
    |> unique_constraint(:email)
    |> unique_constraint([:provider, :uid])
  end
end
