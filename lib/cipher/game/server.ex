defmodule Cipher.Game.Server do
  use GenServer
  require Logger
  alias Cipher.Game

  @idle_timeout :timer.hours(1)

  def start_game do
    game_id = UUID.uuid4()

    child_spec = %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [game_id]},
      restart: :temporary
    }

    case DynamicSupervisor.start_child(Cipher.GameSupervisor, child_spec) do
      {:ok, _pid} -> {:ok, game_id}
      {:error, {:already_started, _pid}} -> {:error, {:already_started, game_id}}
      {:error, reason} -> {:error, reason}
    end
  end

  def start_link(game_id) do
    GenServer.start_link(__MODULE__, game_id, name: via_tuple(game_id))
  end

  def join_game(game_id) do
    case Registry.lookup(Cipher.GameRegistry, game_id) do
      [{pid, _value}] -> GenServer.call(pid, :state)
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
  def init(game_id) do
    state = %{
      id: game_id,
      secret: Game.initialise_secret(),
      guesses: [],
      status: :active
    }

    Logger.info("[#{game_id}] GameServer initialized with secret")
    Logger.debug("[#{game_id}] GameServer state: #{inspect(state)}")
    {:ok, state}
  end

  @impl true
  def handle_call(:state, _from, state) do
    {:reply, {:ok, state}, state}
  end

  @impl true
  def handle_call({:guess, _guess_data}, _from, %{status: status} = state)
      when status != :active do
    Logger.warning("[#{state.id}] Guess blocked - game status is #{status}")
    {:reply, {:error, {:game_not_active, status}}, state}
  end

  @impl true
  def handle_call({:guess, guess_data}, _from, state) do
    with {:ok, guess} <- Game.convert_guess(guess_data) do
      matches = Game.calculate_matches(guess, state.secret)

      updated_state = %{state | guesses: [{guess, matches} | state.guesses]}

      cond do
        matches == 4 ->
          Logger.info("[#{state.id}] Guess correct!")
          won_state = %{updated_state | status: :won}
          {:reply, :correct, won_state, @idle_timeout}

        true ->
          Logger.info("[#{state.id}] Guess incorrect (matches: #{matches})")
          {:reply, {:incorrect, matches}, updated_state, @idle_timeout}
      end
    else
      {:error, {:invalid_choice, kind, value}} ->
        Logger.warning("[#{state.id}] Invalid #{kind}: #{value}")
        {:reply, {:error, {:invalid_choice, kind, value}}, state}

      {:error, {:missing_field, kind}} ->
        Logger.warning("[#{state.id}] Missing field: #{kind}")
        {:reply, {:error, {:missing_field, kind}}, state}

      {:error, {:invalid_format, kind}} ->
        Logger.warning("[#{state.id}] Invalid format for #{kind}")
        {:reply, {:error, {:invalid_format, kind}}, state}
    end
  end

  @impl true
  def handle_info(:timeout, state) do
    Logger.info("[#{state.id}] Idle timeout, marking as expired")
    expired_state = %{state | status: :expired}
    {:noreply, expired_state}
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
end
