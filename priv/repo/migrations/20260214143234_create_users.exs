defmodule Cipher.Repo.Migrations.CreateUsers do
  use Ecto.Migration

  def change do
    create table(:users) do
      add(:email, :string)
      add(:username, :string)
      add(:provider, :string)
      add(:uid, :string)

      timestamps(type: :utc_datetime)
    end

    create(unique_index(:users, [:email]))
    create(unique_index(:users, [:provider, :uid]))
  end
end
