defmodule CipherWeb.GameComponents do
  alias CipherWeb.ChoiceComponents
  alias Cipher.Games.Choice
  use Phoenix.Component

  attr :game, Cipher.Game, required: true

  def game_status_card(assigns) do
    ~H"""
    <div class="flex flex-col items-center mt-8 p-4 alert alert-soft min-w-40">
      <p class="text-sm">Game ID</p>
      <p class="font-mono text-lg">{@game.id}</p>

      <p class="mt-4 text-sm">Difficulty</p>
      <p class={["font-mono text-lg", difficulty_class(@game.difficulty)]}>
        {@game.difficulty}
      </p>

      <p class="mt-4 text-sm">Status</p>
      <p class={["font-mono text-lg", status_class(@game.status)]}>
        {@game.status}
      </p>
    </div>
    """
  end

  attr :index, :integer, required: true
  attr :guess, Cipher.Guess, required: true

  def guess_row(assigns) do
    ~H"""
    <div class="w-full flex items-center flex-row justify-between p-3 gap-2 bg-[#f9f9f8] rounded-md border border-gray-500/30">
      <span class="text-xs font-mono text-gray-500/30 w-6">
        #{@index}
      </span>
      <div class="flex gap-1.5 flex-1 items-center">
        <div
          :for={choice <- Enum.sort(@guess.choices, &Choice.compare/2)}
          class="size-8 badge badge-soft flex items-center justify-center"
        >
          <ChoiceComponents.icon choice={choice} />
        </div>
      </div>
      <div class="flex items-center justify-center size-10 rounded-lg badge badge-accent font-bold">
        {@guess.matches}
      </div>
    </div>
    """
  end

  def difficulty_class(:easy), do: "text-green-500"
  def difficulty_class(:normal), do: "text-blue-500"
  def difficulty_class(:hard), do: "text-red-500"

  def status_class(:active), do: "text-lime-500"
  def status_class(:won), do: "text-indigo-400"
  def status_class(:expired), do: "text-red-500"
  def status_class(_), do: "text-gray-500"
end
