defmodule CipherWeb.UserLive.History do
  use CipherWeb, :live_view

  alias CipherWeb.Layouts

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="mx-auto max-w-sm space-y-4 grid place-items-center">
        <h1>Coming soon</h1>
        <p>We're working on this page!</p>
      </div>
    </Layouts.app>
    """
  end
end
