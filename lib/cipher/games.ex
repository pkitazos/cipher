defmodule Cipher.Games do
  @moduledoc """
  The Games context.
  """
  require Logger
  import Ecto.Query, warn: false
  alias Cipher.Repo
  alias Cipher.Game, as: GameDTO
  alias Cipher.Games.{Game, Guess, Logic, Server, Choice}

  @doc """
  Orchestrates creating a game.
  1. Generates secret (Logic)
  2. Saves to DB (Repo)
  3. Starts GenServer (Server)
  """
  def start_new_game(user, difficulty) do
    secret_structs = Logic.initialise_secret(difficulty)

    Logger.info("[new game] secret: #{inspect(secret_structs)}")

    attrs = %{
      user_id: user.id,
      difficulty: difficulty,
      secret: Enum.map(secret_structs, & &1.name)
    }

    # We use Repo.transaction to ensure we don't create a DB record
    # if the Server fails to start.
    Cipher.Repo.transaction(fn ->
      with {:ok, db_record} <- create_game(attrs),
           game <- GameDTO.new(db_record),
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
  Gets the game state.
  If the GenServer is down (e.g., after a deploy), it transparently restarts it.
  """
  def get_running_game(game_id) do
    case Server.get_client_state(game_id) do
      {:ok, state} -> {:ok, state}
      {:error, :game_not_found} -> restore_game_session(game_id)
    end
  end

  # Private helper to handle the "Cold Boot" logic
  defp restore_game_session(game_id) do
    case get_game_with_history(game_id) do
      nil ->
        {:error, :not_found}

      db_record ->
        game_dto = GameDTO.new(db_record)
        {:ok, _pid} = Server.ensure_started(game_dto)
        {:ok, GameDTO.client_view(game_dto)}
    end
  end

  defp get_game_with_history(id) do
    Game
    |> Repo.get(id)
    |> Repo.preload(guesses: from(g in Guess, order_by: [desc: g.inserted_at]))
  end

  def get_game_with_history!(id) do
    Game
    |> Repo.get!(id)
    |> Repo.preload(guesses: from(g in Guess, order_by: [desc: g.inserted_at]))
  end

  @doc """
  Submits a guess to the running game.
  Accepts a map of %{kind => %Choice{}} (from the UI)
  and converts it to a MapSet for the Server.
  """
  def make_guess(game_id, guess_map) do
    {:ok, game} = get_running_game(game_id)

    # convert UI Map -> domain MapSet
    guess_set =
      guess_map
      |> Map.values()
      |> MapSet.new()

    case Cipher.Games.Logic.validate_guess(guess_set, game.difficulty) do
      :ok ->
        Server.guess(game_id, guess_set)

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Progresses the user to the next difficulty level.
  1. Checks the current game's settings.
  2. Calculates the next difficulty.
  3. Starts a completely new game instance.
  """
  def level_up(current_game_id) do
    current_game = Repo.get!(Cipher.Games.Game, current_game_id)

    case Cipher.Games.Logic.next_difficulty(current_game.difficulty) do
      {:ok, next_difficulty} ->
        user_stub = %{id: current_game.user_id}
        start_new_game(user_stub, next_difficulty)

      {:error, reason} ->
        {:error, reason}
    end
  end

  def abandon_game(current_game_id) do
    db_record = Repo.get!(Cipher.Games.Game, current_game_id)
    game_state = GameDTO.new(db_record)
    update_game(db_record, %{status: :abandoned})
    Server.stop(current_game_id)
    {:ok, %{game_state | status: :abandoned}}
  end

  def parse_guess_input(params) do
    Enum.reduce_while(params, {:ok, %{}}, fn {kind_str, value_str}, {:ok, acc} ->
      with {:ok, kind_atom} <- Choice.kind_from_string(kind_str),
           {:ok, choice_struct} <- Choice.from_string(value_str),
           true <- choice_struct.kind == kind_atom do
        {:cont, {:ok, Map.put(acc, kind_atom, choice_struct)}}
      else
        _ -> {:halt, {:error, :invalid_parameters}}
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
