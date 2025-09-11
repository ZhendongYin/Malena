defmodule AiChatWeb.RegistrationController do
  use AiChatWeb, :controller
  alias AiChat.Accounts
  alias AiChat.Accounts.Guardian
  alias AiChat.Organizations

  def new(conn, _params) do
    changeset = Accounts.change_user_registration(%Accounts.User{})
    departments = Organizations.list_departments()
    roles = Organizations.list_roles()

    render(conn, "new.html",
      changeset: changeset,
      departments: departments,
      roles: roles
    )
  end

  def create(conn, %{"user" => user_params}) do
    case Accounts.register_user(user_params) do
      {:ok, user} ->
        # Determine redirect based on user role
        redirect_to = case user.role.name do
          "Super Admin" -> ~p"/admin/dashboard"
          _ -> ~p"/dashboard"
        end

        conn
        |> Guardian.Plug.sign_in(user)
        |> put_flash(:info, "Account created successfully!")
        |> redirect(to: redirect_to)

      {:error, %Ecto.Changeset{} = changeset} ->
        departments = Organizations.list_departments()
        roles = Organizations.list_roles()

        render(conn, "new.html",
          changeset: changeset,
          departments: departments,
          roles: roles
        )
    end
  end
end
