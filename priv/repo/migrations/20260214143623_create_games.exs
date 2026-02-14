defmodule Cipher.Repo.Migrations.CreateGames do
  use Ecto.Migration

  def change do
    create table(:games) do
      add :status, :string
      add :difficulty, :string
      add :secret, {:array, :string}
      add :user_id, references(:users, on_delete: :nothing)

      timestamps(type: :utc_datetime)
    end

    create index(:games, [:user_id])
  end
end
