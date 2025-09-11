defmodule AiChatWeb.AuthErrorHandler do
  import Plug.Conn
  import Phoenix.Controller

  def auth_error(conn, {_type, _reason}, _opts) do
    conn
    |> put_flash(:error, "You must be logged in to access this page.")
    |> redirect(to: "/login")
    |> halt()
  end
end


