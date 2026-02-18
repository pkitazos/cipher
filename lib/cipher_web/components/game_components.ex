defmodule CipherWeb.GameComponents do
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

  def difficulty_class(:easy), do: "text-green-500"
  def difficulty_class(:normal), do: "text-blue-500"
  def difficulty_class(:hard), do: "text-red-500"

  def status_class(:active), do: "text-lime-500"
  def status_class(:won), do: "text-indigo-400"
  def status_class(:expired), do: "text-red-500"
  def status_class(_), do: "text-gray-500"
end
