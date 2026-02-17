defmodule Cipher.Games do
  @moduledoc """
  The Games context.
  """
  require Logger
  import Ecto.Query, warn: false
  alias Cipher.Repo
  alias Cipher.Game, as: GameDTO
  alias Cipher.Games.{Game, Guess, Logic, Server}

  # --- Game Lifecycle (Creation & Progression) ---

  @doc """
  Orchestrates creating a game.
  1. Generates secret (Logic)
  2. Saves to DB (Repo)
  3. Starts GenServer (Server)
  """
  def start_new_game(identifier, difficulty) do
    secret_structs = Logic.initialise_secret(difficulty)
    Logger.info("[new game] secret: #{inspect(secret_structs)}")

    attrs =
      case identifier do
        %{id: user_id} -> %{user_id: user_id, difficulty: difficulty}
        session_id when is_binary(session_id) -> %{session_id: session_id, difficulty: difficulty}
      end
      |> Map.put(:secret, Enum.map(secret_structs, & &1.name))

    # We use Repo.transaction to ensure we don't create a DB record
    # if the Server fails to start.
    Cipher.Repo.transaction(fn ->
      with {:ok, db_record} <- create_game(attrs),
           game_dto <- GameDTO.new(%{db_record | guesses: []}),
           {:ok, _pid} <- Server.ensure_started(game_dto) do
        game_dto
      else
        {:error, reason} ->
          Logger.error("Failed to start game: #{inspect(reason)}")
          Cipher.Repo.rollback(reason)
      end
    end)
  end

  @doc """
  Progresses the user to the next difficulty level.
  1. Verifies the current game is actually won.
  2. Calculates the next difficulty.
  3. Starts a completely new game instance.
  4. Stops the old game process.
  """
  def level_up(current_game_id) do
    with {:ok, current_state} <- Server.get_client_state(current_game_id),
         true <- current_state.status == :won,
         {:ok, next_difficulty} <- Logic.next_difficulty(current_state.difficulty) do
      identifier =
        if current_state.user_id do
          %{id: current_state.user_id}
        else
          current_state.session_id
        end

      {:ok, new_game} = start_new_game(identifier, next_difficulty)

      # The 'won' status was already persisted in make_guess
      # so we don't need any additional db operation
      Server.stop(current_game_id)

      {:ok, new_game}
    else
      false -> {:error, :game_not_won}
      {:error, :game_not_found} -> {:error, :game_not_found}
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Cleanly ends the current game session.
  - If the game is :active, it marks it as :abandoned and persists that.
  - If the game is already :won or :abandoned, it simply stops the process without changing history.
  """
  def abandon_game(game_id) do
    case Server.get_client_state(game_id) do
      {:ok, state} ->
        if state.status == :active do
          Server.abandon_game(game_id)

          game_record = Repo.get!(Game, game_id)
          update_game(game_record, %{status: :abandoned})
        end

        Server.stop(game_id)

        {:ok, state}

      {:error, :game_not_found} ->
        case Repo.get(Game, game_id) do
          nil ->
            {:error, :game_not_found}

          %Game{status: status} = game ->
            game =
              if status == :active do
                {:ok, updated} = update_game(game, %{status: :abandoned})
                updated
              else
                game
              end

            # Preload before DTO conversion
            game_with_history =
              Repo.preload(game, guesses: from(g in Guess, order_by: [desc: g.inserted_at]))

            {:ok, GameDTO.new(game_with_history)}
        end
    end
  end

  # --- Gameplay (Guessing) ---

  @doc """
  Submits a guess to the running game and persists the result.
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

    Repo.transaction(fn ->
      with :ok <- Logic.validate_guess(guess_set, game.difficulty),
           {:ok, new_state} <- Server.guess(game_id, guess_set),
           {:ok, _guess_record} <- persist_turn_outcome(game_id, new_state) do
        new_state
      else
        {:error, reason} -> Repo.rollback(reason)
      end
    end)
  end

  defp persist_turn_outcome(game_id, new_state) do
    # grab the matches from the new state (head of the list is latest)
    {guess_set, matches} = hd(new_state.guesses)

    guess_attrs = %{
      game_id: game_id,
      matches: matches,
      # MapSet<Struct> -> List<Atom>
      choices: Enum.map(guess_set, & &1.name)
    }

    with {:ok, guess_record} <- create_guess(guess_attrs) do
      # only update Game status if it transitioned (e.g. active -> won)
      if new_state.status != :active do
        game_record = Repo.get!(Game, game_id)
        update_game(game_record, %{status: new_state.status})
      else
        {:ok, guess_record}
      end
    end
  end

  # --- History & Leaderboard ---

  @doc """
  Claims all games associated with a session_id by assigning them to a user.
  Used when a guest user registers an account.
  """
  def claim_guest_games(session_id, user_id) do
    from(g in Game,
      where: g.session_id == ^session_id and is_nil(g.user_id)
    )
    |> Repo.update_all(set: [user_id: user_id])
  end

  @doc """
  Returns the game history for a specific user, ordered by newest first.
  Includes the guess count.
  """
  def list_user_games(user_id) do
    from(g in Game,
      where: g.user_id == ^user_id,
      left_join: guesses in assoc(g, :guesses),
      group_by: g.id,
      # merge the count into the virtual field
      # we count the ID of the joined table 'guesses', not 'g.guesses'
      select_merge: %{num_guesses: count(guesses.id)},
      order_by: [desc: g.inserted_at],
      preload: [guesses: ^from(g in Guess, order_by: [desc: g.inserted_at])]
    )
    |> Repo.all()
    |> Enum.map(&GameDTO.new/1)
  end

  @doc """
  Returns the top n (default: 10) won games for a specific difficulty.
  Ordered by:
  1. Fewest Guesses
  2. Shortest Duration - calculated as (updated_at - inserted_at)
  """
  def leaderboard(difficulty, limit \\ 10) do
    # find the top games
    top_ids =
      from(g in Game,
        where: g.status == :won and g.difficulty == ^difficulty,
        left_join: guesses in assoc(g, :guesses),
        group_by: g.id,
        order_by: [
          asc: count(guesses.id),
          asc: fragment("? - ?", g.updated_at, g.inserted_at)
        ],
        limit: ^limit,
        select: g.id
      )
      |> Repo.all()

    # fetch full data for games to construct corerct DTO
    from(g in Game,
      where: g.id in ^top_ids,
      preload: [guesses: ^from(g in Guess, order_by: [desc: g.inserted_at])],
      # maintain the leaderboard order using `array_position`
      # Postgres-specific so we need to escape to SQL for this
      order_by: [asc: fragment("array_position(?, ?)", ^top_ids, g.id)]
    )
    |> Repo.all()
    |> Enum.map(&GameDTO.new/1)
  end

  # --- State Recovery ---

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

  defp restore_game_session(game_id) do
    case get_game_with_history(game_id) do
      nil ->
        {:error, :not_found}

      db_record ->
        game_dto = GameDTO.new(db_record)

        if game_dto.status == :active do
          {:ok, _pid} = Server.ensure_started(game_dto)
        end

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

  # --- CRUD ---

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
