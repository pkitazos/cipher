defmodule Cipher.Repo.Migrations.CreateGuesses do
  use Ecto.Migration

  def change do
    create table(:guesses) do
      add :matches, :integer
      add :choices, {:array, :string}
      add :game_id, references(:games, on_delete: :nothing)

      timestamps(type: :utc_datetime)
    end

    create index(:guesses, [:game_id])
  end
end
