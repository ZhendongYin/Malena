defmodule AiChatWeb.PageController do
  use AiChatWeb, :controller
  alias AiChat.Accounts.Guardian

  def home(conn, _params) do
    case Guardian.Plug.current_resource(conn) do
      nil ->
        render(conn, "home.html")

      user ->
        # Preload role association
        user = AiChat.Repo.preload(user, :role)

        # Determine redirect based on user role
        redirect_to = case user.role do
          %{name: "Super Admin"} -> ~p"/admin/dashboard"
          _ -> ~p"/dashboard"
        end
        redirect(conn, to: redirect_to)
    end
  end

  def dashboard(conn, _params) do
    user = conn.assigns.current_user

    render(conn, "dashboard.html", user: user)
  end
end
