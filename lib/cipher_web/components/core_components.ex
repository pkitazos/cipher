defmodule CipherWeb.CoreComponents do
  use Phoenix.Component

  alias Phoenix.LiveView.JS

  @doc """
  Renders a button.
  """
  attr :type, :string, default: nil
  attr :class, :string, default: nil
  attr :rest, :global, include: ~w(disabled form name value)

  slot :inner_block, required: true

  def button(assigns) do
    ~H"""
    <button
      type={@type}
      class={[
        "rounded-lg px-4 py-2 text-sm font-semibold",
        @class || "bg-zinc-900 text-white hover:bg-zinc-700 active:bg-zinc-800"
      ]}
      {@rest}
    >
      {render_slot(@inner_block)}
    </button>
    """
  end
end
