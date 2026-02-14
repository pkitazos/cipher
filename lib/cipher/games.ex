defmodule Cipher.Games do
  @moduledoc """
  The Games context.
  """
  require Logger
  import Ecto.Query, warn: false
  alias Cipher.Repo
  alias Cipher.Games.{Game, Guess, Logic, Server}

  @doc """
  Orchestrates creating a game.
  1. Generates secret (Logic)
  2. Saves to DB (Repo)
  3. Starts GenServer (Server)
  """
  def start_new_game(user, difficulty) do
    secret_structs = Logic.initialise_secret(difficulty)

    attrs = %{
      user_id: user.id,
      difficulty: difficulty,
      secret: Enum.map(secret_structs, & &1.name),
      status: :active
    }

    # We use Repo.transaction to ensure we don't create a DB record
    # if the Server fails to start.
    Cipher.Repo.transaction(fn ->
      with {:ok, game} <- create_game(attrs),
           {:ok, _pid} <- Server.ensure_started(game) do
        game
      else
        {:error, reason} ->
          Logger.error("Failed to start game: #{inspect(reason)}")
          Cipher.Repo.rollback(reason)
      end
    end)
  end

  @doc """
  Returns the list of games.

  ## Examples

      iex> list_games()
      [%Game{}, ...]

  """
  def list_games do
    Repo.all(Game)
  end

  @doc """
  Gets a single game.

  Raises `Ecto.NoResultsError` if the Game does not exist.

  ## Examples

      iex> get_game!(123)
      %Game{}

      iex> get_game!(456)
      ** (Ecto.NoResultsError)

  """
  def get_game!(id), do: Repo.get!(Game, id)

  @doc """
  Creates a game.

  ## Examples

      iex> create_game(%{field: value})
      {:ok, %Game{}}

      iex> create_game(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_game(attrs) do
    %Game{}
    |> Game.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a game.

  ## Examples

      iex> update_game(game, %{field: new_value})
      {:ok, %Game{}}

      iex> update_game(game, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_game(%Game{} = game, attrs) do
    game
    |> Game.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a game.

  ## Examples

      iex> delete_game(game)
      {:ok, %Game{}}

      iex> delete_game(game)
      {:error, %Ecto.Changeset{}}

  """
  def delete_game(%Game{} = game) do
    Repo.delete(game)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking game changes.

  ## Examples

      iex> change_game(game)
      %Ecto.Changeset{data: %Game{}}

  """
  def change_game(%Game{} = game, attrs \\ %{}) do
    Game.changeset(game, attrs)
  end

  alias Cipher.Games.Guess

  @doc """
  Returns the list of guesses.

  ## Examples

      iex> list_guesses()
      [%Guess{}, ...]

  """
  def list_guesses do
    Repo.all(Guess)
  end

  @doc """
  Gets a single guess.

  Raises `Ecto.NoResultsError` if the Guess does not exist.

  ## Examples

      iex> get_guess!(123)
      %Guess{}

      iex> get_guess!(456)
      ** (Ecto.NoResultsError)

  """
  def get_guess!(id), do: Repo.get!(Guess, id)

  @doc """
  Creates a guess.

  ## Examples

      iex> create_guess(%{field: value})
      {:ok, %Guess{}}

      iex> create_guess(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_guess(attrs) do
    %Guess{}
    |> Guess.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a guess.

  ## Examples

      iex> update_guess(guess, %{field: new_value})
      {:ok, %Guess{}}

      iex> update_guess(guess, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_guess(%Guess{} = guess, attrs) do
    guess
    |> Guess.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a guess.

  ## Examples

      iex> delete_guess(guess)
      {:ok, %Guess{}}

      iex> delete_guess(guess)
      {:error, %Ecto.Changeset{}}

  """
  def delete_guess(%Guess{} = guess) do
    Repo.delete(guess)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking guess changes.

  ## Examples

      iex> change_guess(guess)
      %Ecto.Changeset{data: %Guess{}}

  """
  def change_guess(%Guess{} = guess, attrs \\ %{}) do
    Guess.changeset(guess, attrs)
  end
end
