defmodule AiChatWeb.SessionController do
  use AiChatWeb, :controller
  alias AiChat.Accounts
  alias AiChat.Accounts.Guardian

  def new(conn, _params) do
    render(conn, "new.html")
  end

  def create(conn, %{"session" => %{"email" => email, "password" => password}}) do
    case Accounts.authenticate_user(email, password) do
      {:ok, user} ->
        # All users go directly to chat interface
        redirect_to = ~p"/chat"

        conn
        |> Guardian.Plug.sign_in(user)
        |> put_flash(:info, "Welcome back!")
        |> redirect(to: redirect_to)

      {:error, :invalid_credentials} ->
        conn
        |> put_flash(:error, "Invalid email or password")
        |> render("new.html")
    end
  end

  def delete(conn, _params) do
    conn
    |> Guardian.Plug.sign_out()
    |> put_flash(:info, "You have been logged out")
    |> redirect(to: ~p"/")
  end
end
