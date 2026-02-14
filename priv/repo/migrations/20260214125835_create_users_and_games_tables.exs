defmodule Cipher.Repo.Migrations.CreateUsersAndGamesTables do
  use Ecto.Migration

  def up do
    # 1. Create Users Table (for future auth)
    create table(:users) do
      add(:email, :string)
      add(:username, :string)
      add(:provider, :string)
      add(:uid, :string)

      timestamps()
    end

    create(unique_index(:users, [:email]))
    create(unique_index(:users, [:provider, :uid]))

    # 2. Create Custom ENUM Type for Choices
    # This matches the list in Cipher.Games.Choice
    execute("CREATE TYPE choice_name AS ENUM (
      'circle', 'square', 'star', 'triangle',
      'red', 'green', 'blue', 'yellow',
      'vertical_stripes', 'horizontal_stripes', 'checkered', 'dotted',
      'top', 'bottom', 'left', 'right',
      'tiny', 'small', 'medium', 'large'
    )")

    # 3. Create Games Table
    create table(:games) do
      add(:status, :string, null: false, default: "active")
      add(:difficulty, :string, null: false)
      # 'secret' is an array of our custom ENUM type
      add(:secret, :choice_name, array: true, null: false)

      add(:user_id, references(:users, on_delete: :nilify_all))

      timestamps()
    end

    create(index(:games, [:user_id]))
    create(index(:games, [:status, :updated_at]))

    # 4. Create Guesses Table
    create table(:guesses) do
      add(:matches, :integer, null: false)
      # 'choices' is an array of our custom ENUM type
      add(:choices, :choice_name, array: true, null: false)

      add(:game_id, references(:games, on_delete: :delete_all))

      timestamps()
    end

    create(index(:guesses, [:game_id, :inserted_at]))
  end

  def down do
    drop(table(:guesses))
    drop(table(:games))
    execute("DROP TYPE choice_name")
    drop(table(:users))
  end
end
