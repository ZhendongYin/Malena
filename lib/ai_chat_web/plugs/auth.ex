defmodule AiChatWeb.Plugs.Auth do
  @moduledoc """
  Authentication plug for web requests.
  """

  import Plug.Conn
  import Phoenix.Controller
  alias AiChat.Accounts.Guardian
  alias AiChat.Repo

  def init(opts), do: opts

  def call(conn, _opts) do
    case Guardian.Plug.current_resource(conn) do
      nil ->
        conn
        |> put_flash(:error, "You must be logged in to access this page.")
        |> redirect(to: "/login")
        |> halt()

      user ->
        user = Repo.preload(user, [:department, :role])
        assign(conn, :current_user, user)
    end
  end

  @doc """
  Optional authentication - doesn't redirect if not authenticated.
  """
  def optional_auth(conn, _opts) do
    case Guardian.Plug.current_resource(conn) do
      nil ->
        conn

      user ->
        assign(conn, :current_user, user)
    end
  end
end
