defmodule CipherWeb.UserLive.Settings do
  use CipherWeb, :live_view

  on_mount {CipherWeb.UserAuth, :require_sudo_mode}

  alias CipherWeb.Layouts
  alias Cipher.Accounts

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="max-w-2xl mx-auto py-8 px-4 space-y-6">
        <h1 class="text-2xl font-bold text-base-content">Settings</h1>

        <%!-- Profile --%>
        <div class="border border-base-300 rounded-lg bg-base-100 p-6">
          <h2 class="text-sm font-semibold text-base-content uppercase tracking-wide mb-4">
            Profile
          </h2>
          <div class="flex items-center gap-4 mb-6">
            <div class="w-14 h-14 rounded-full bg-base-200 grid place-items-center">
              <.icon name="hero-user-circle" class="w-10 h-10 text-base-content/30" />
            </div>
            <div>
              <p class="font-medium text-base-content">{@current_scope.user.email}</p>
              <p class="text-xs text-base-content/50">Member</p>
            </div>
          </div>

          <div class="divider my-0" />

          <div class="pt-4">
            <h3 class="text-sm font-medium text-base-content mb-3">Change email</h3>
            <.form
              for={@email_form}
              id="email_form"
              phx-submit="update_email"
              phx-change="validate_email"
              class="space-y-3"
            >
              <.input
                field={@email_form[:email]}
                type="email"
                label="Email"
                autocomplete="username"
                required
              />
              <.button variant="primary" phx-disable-with="Changing...">
                Update email
              </.button>
            </.form>
          </div>
        </div>

        <%!-- Appearance --%>
        <div class="border border-base-300 rounded-lg bg-base-100 p-6">
          <h2 class="text-sm font-semibold text-base-content uppercase tracking-wide mb-4">
            Appearance
          </h2>
          <div class="flex items-center justify-between">
            <div>
              <p class="text-sm font-medium text-base-content">Theme</p>
              <p class="text-xs text-base-content/50">Choose between light, dark, or system</p>
            </div>
            <Layouts.theme_toggle />
          </div>
        </div>

        <%!-- Game History --%>
        <div class="border border-base-300 rounded-lg bg-base-100 p-6">
          <h2 class="text-sm font-semibold text-base-content uppercase tracking-wide mb-4">
            Game History
          </h2>
          <p class="text-sm text-base-content/50 mb-4">
            View your past games, stats, and streaks.
          </p>
          <.link
            navigate={~p"/games/history"}
            class="btn btn-sm btn-ghost gap-2 text-sm px-3 text-accent"
          >
            View game history <.icon name="hero-arrow-right-micro" class="w-4 h-4" />
          </.link>
        </div>

        <%!-- Account --%>
        <div class="border border-base-300 rounded-lg bg-base-100 p-6">
          <h2 class="text-sm font-semibold text-base-content uppercase tracking-wide mb-4">
            Account
          </h2>
          <.link
            href={~p"/users/log-out"}
            method="delete"
            class="btn btn-sm btn-error btn-soft"
          >
            <.icon name="hero-arrow-right-start-on-rectangle-micro" class="w-4 h-4" /> Log out
          </.link>
        </div>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(%{"token" => token}, _session, socket) do
    socket =
      case Accounts.update_user_email(socket.assigns.current_scope.user, token) do
        {:ok, _user} ->
          put_flash(socket, :info, "Email changed successfully.")

        {:error, _} ->
          put_flash(socket, :error, "Email change link is invalid or it has expired.")
      end

    {:ok, push_navigate(socket, to: ~p"/users/settings")}
  end

  def mount(_params, _session, socket) do
    user = socket.assigns.current_scope.user
    email_changeset = Accounts.change_user_email(user, %{}, validate_unique: false)

    socket =
      socket
      |> assign(:current_email, user.email)
      |> assign(:email_form, to_form(email_changeset))

    {:ok, socket}
  end

  @impl true
  def handle_event("validate_email", params, socket) do
    %{"user" => user_params} = params

    email_form =
      socket.assigns.current_scope.user
      |> Accounts.change_user_email(user_params, validate_unique: false)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, email_form: email_form)}
  end

  def handle_event("update_email", params, socket) do
    %{"user" => user_params} = params
    user = socket.assigns.current_scope.user
    true = Accounts.sudo_mode?(user)

    case Accounts.change_user_email(user, user_params) do
      %{valid?: true} = changeset ->
        Accounts.deliver_user_update_email_instructions(
          Ecto.Changeset.apply_action!(changeset, :insert),
          user.email,
          &url(~p"/users/settings/confirm-email/#{&1}")
        )

        info = "A link to confirm your email change has been sent to the new address."
        {:noreply, socket |> put_flash(:info, info)}

      changeset ->
        {:noreply, assign(socket, :email_form, to_form(changeset, action: :insert))}
    end
  end
end
