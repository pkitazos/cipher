defmodule CipherWeb.Plugs.GuestSession do
  import Plug.Conn

  def init(opts), do: opts

  def call(conn, _opts) do
    case get_session(conn, :guest_session_id) do
      nil ->
        guest_id = Ecto.UUID.generate()
        put_session(conn, :guest_session_id, guest_id)

      _existing ->
        conn
    end
  end
end
