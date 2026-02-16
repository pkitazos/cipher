defmodule Cipher.Games.Server do
  use GenServer
  require Logger

  alias Cipher.Games.Logic

  @idle_timeout :timer.hours(1)

  def ensure_started(game) do
    child_spec = %{
      id: {__MODULE__, game.id},
      start: {__MODULE__, :start_link, [game]},
      restart: :temporary
    }

    case DynamicSupervisor.start_child(Cipher.GameSupervisor, child_spec) do
      {:ok, pid} -> {:ok, pid}
      {:error, {:already_started, pid}} -> {:ok, pid}
      {:error, reason} -> {:error, reason}
    end
  end

  def start_link(game) do
    GenServer.start_link(__MODULE__, game, name: via_tuple(game.id))
  end

  def stop(game_id) do
    case GenServer.whereis(via_tuple(game_id)) do
      nil -> :ok
      pid -> GenServer.stop(pid)
    end
  end

  def abandon_game(game_id) do
    case Registry.lookup(Cipher.GameRegistry, game_id) do
      [{pid, _value}] -> GenServer.call(pid, :mark_abandoned)
      [] -> {:error, :game_not_found}
    end
  end

  def get_client_state(game_id) do
    case Registry.lookup(Cipher.GameRegistry, game_id) do
      [{pid, _value}] -> GenServer.call(pid, :client_state)
      [] -> {:error, :game_not_found}
    end
  end

  def guess(game_id, guess_data) do
    case Registry.lookup(Cipher.GameRegistry, game_id) do
      [{pid, _value}] -> GenServer.call(pid, {:guess, guess_data})
      [] -> {:error, :game_not_found}
    end
  end

  @impl true
  def init(game) do
    # The Server calls the Context, and the Context calls the Repo.
    # This restores the state if the server crashes and restarts.
    Logger.info("[#{game.id}] GameServer started for Game ##{game.id}")
    {:ok, game, @idle_timeout}
  end

  @impl true
  def handle_call(:mark_abandoned, _from, state) do
    updated_state = %{state | status: :abandoned}
    {:reply, {:ok, updated_state}, state, @idle_timeout}
  end

  @impl true
  def handle_call(:internal_state, _from, state) do
    {:reply, {:ok, state}, state, @idle_timeout}
  end

  @impl true
  def handle_call(:client_state, _from, state) do
    client_safe_state = Map.drop(state, [:secret])
    {:reply, {:ok, client_safe_state}, state, @idle_timeout}
  end

  @impl true
  def handle_call({:guess, _guess_data}, _from, %{status: status} = state)
      when status != :active do
    Logger.warning("[#{state.id}] Guess blocked - game status is #{status}")
    {:reply, {:error, {:game_not_active, status}}, state, @idle_timeout}
  end

  # Handle MapSet guess (from LiveView/TUI - already converted)
  @impl true
  def handle_call({:guess, %MapSet{} = guess}, _from, state) do
    Logger.info("[#{state.id}] Guess data : #{inspect(guess)}")
    Logger.info("[#{state.id}] Secret : #{inspect(state.secret)}")

    matches = Logic.calculate_matches(guess, state.secret)
    secret_size = MapSet.size(state.secret)

    updated_state = %{state | guesses: [{guess, matches} | state.guesses], last_matches: matches}

    cond do
      matches == secret_size ->
        Logger.info("[#{state.id}] Guess correct!")
        won_state = %{updated_state | status: :won}
        {:reply, {:ok, Map.drop(won_state, [:secret])}, won_state, @idle_timeout}

      true ->
        Logger.info("[#{state.id}] Guess incorrect (matches: #{matches})")
        {:reply, {:ok, Map.drop(updated_state, [:secret])}, updated_state, @idle_timeout}
    end
  end

  # Handle string map guess (from HTTP API - needs conversion)
  @impl true
  def handle_call({:guess, guess_data}, _from, state) when is_map(guess_data) do
    with {:ok, guess} <- Logic.convert_guess_from_strings(guess_data, state.difficulty) do
      matches = Logic.calculate_matches(guess, state.secret)
      secret_size = MapSet.size(state.secret)

      updated_state = %{
        state
        | guesses: [{guess, matches} | state.guesses],
          last_matches: matches
      }

      new_status = if matches == secret_size, do: :won, else: :active

      final_state = %{updated_state | status: new_status}

      Logger.info(
        "[#{state.id}] Guess #{if new_status == :won, do: "correct", else: "incorrect"} (matches: #{matches})"
      )

      filtered_state = Map.drop(final_state, [:secret])
      {:reply, {:ok, filtered_state}, final_state, @idle_timeout}
    else
      {:error, {:invalid_choice, kind, value}} ->
        Logger.warning("[#{state.id}] Invalid #{kind}: #{value}")
        {:reply, {:error, {:invalid_choice, kind, value}}, state, @idle_timeout}

      {:error, {:missing_field, kind}} ->
        Logger.warning("[#{state.id}] Missing field: #{kind}")
        {:reply, {:error, {:missing_field, kind}}, state, @idle_timeout}

      {:error, {:invalid_format, kind}} ->
        Logger.warning("[#{state.id}] Invalid format for #{kind}")
        {:reply, {:error, {:invalid_format, kind}}, state, @idle_timeout}
    end
  end

  @impl true
  def handle_info(:timeout, state) do
    Logger.info("[#{state.id}] Idle timeout, marking as abandoned")
    abandoned_state = %{state | status: :abandoned}
    {:noreply, abandoned_state}
  end

  @impl true
  def handle_info(msg, state) do
    Logger.warning("[#{state.id}] Received unexpected message: #{inspect(msg)}")
    {:noreply, state}
  end

  @impl true
  def terminate(reason, state) do
    Logger.info("[#{state.id}] Terminating: #{inspect(reason)}")
    :ok
  end

  def via_tuple(game_id) do
    {:via, Registry, {Cipher.GameRegistry, game_id}}
  end

  if Mix.env() == :test do
    @doc """
    Test-only function to get full internal state including secret.

    DO NOT use in production code or from controllers/LiveView.
    This function only exists in the test environment and is used to verify
    game logic correctness in tests.

    For production code, use `get_client_state/1` which filters the secret.
    """
    def get_internal_state(game_id) do
      case Registry.lookup(Cipher.GameRegistry, game_id) do
        [{pid, _value}] -> GenServer.call(pid, :internal_state)
        [] -> {:error, :game_not_found}
      end
    end
  end
end
