defmodule SecretSeeker.Game.Server do
  use GenServer
  alias SecretSeeker.Game

  @idle_timeout :timer.hours(1)

  def start_game do
    game_id = UUID.uuid4()

    child_spec = %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [game_id]},
      restart: :temporary
    }

    case DynamicSupervisor.start_child(SecretSeeker.GameSupervisor, child_spec) do
      {:ok, _pid} -> {:ok, game_id}
      {:error, {:already_started, _pid}} -> {:error, {:already_started, game_id}}
      {:error, reason} -> {:error, reason}
    end
  end

  def start_link(game_id) do
    GenServer.start_link(__MODULE__, game_id, name: via_tuple(game_id))
  end

  def join_game(game_id) do
    case Registry.lookup(SecretSeeker.GameRegistry, game_id) do
      [{pid, _value}] -> GenServer.call(pid, :state)
      [] -> {:error, :game_not_found}
    end
  end

  def guess(game_id, guess_data) do
    case Registry.lookup(SecretSeeker.GameRegistry, game_id) do
      [{pid, _value}] -> GenServer.call(pid, {:guess, guess_data})
      [] -> {:error, :game_not_found}
    end
  end

  @impl true
  def init(game_id) do
    state = %{
      id: game_id,
      secret: Game.initialise_secret(),
      guesses: []
    }

    IO.inspect(state, label: "[#{game_id}] GameServer init")
    {:ok, state}
  end

  @impl true
  def handle_call(:state, _from, state) do
    {:reply, {:ok, state}, state}
  end

  @impl true
  def handle_call({:guess, guess_data}, _from, state) do
    with {:ok, guess} <- Game.convert_guess(guess_data) do
      IO.inspect(guess_data, label: :guess_data)
      IO.inspect(guess, label: :guess)
      score = Game.calculate_score(guess, state.secret)

      updated_state = %{state | guesses: [guess | state.guesses]}

      cond do
        score == 4 ->
          IO.puts("[#{state.id}] GameServer: Guess correct!")
          {:reply, :correct, updated_state, @idle_timeout}

        true ->
          IO.puts("[#{state.id}] GameServer: Guess incorrect (score: #{score})")
          {:reply, {:incorrect, score}, updated_state, @idle_timeout}
      end
    else
      {:error, :invalid_guess} ->
        IO.puts("[#{state.id}] GameServer: Invalid guess: #{inspect(guess_data)}")
        {:reply, {:error, :invalid_guess_format}, state}
    end
  end

  @impl true
  def handle_info(:timeout, state) do
    IO.puts("[#{state.id}] GameServer: Idle timeout, stopping.")
    {:stop, :normal, state}
  end

  @impl true
  def handle_info(msg, state) do
    IO.inspect(msg, label: "[#{state.id}] GameServer received unexpected message")
    {:noreply, state}
  end

  @impl true
  def terminate(reason, state) do
    IO.inspect(reason, label: "[#{state.id}] GameServer terminating")
    :ok
  end

  def via_tuple(game_id) do
    {:via, Registry, {SecretSeeker.GameRegistry, game_id}}
  end
end
