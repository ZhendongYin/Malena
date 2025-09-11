defmodule AiChatWeb.Admin.UserController do
  use AiChatWeb, :controller

  alias AiChat.Accounts
  alias AiChat.Organizations
  alias AiChat.Repo

  plug AiChatWeb.Plugs.Authorization, :manage_users when action in [:index, :new, :create, :show, :edit, :update, :delete]

  def index(conn, _params) do
    users = Accounts.list_users() |> Repo.preload([:role, :department])
    render(conn, "index.html", users: users)
  end

  def new(conn, _params) do
    changeset = %Ecto.Changeset{data: %Accounts.User{is_active: true}, valid?: true, errors: []}
    departments = Organizations.list_departments()
    roles = Organizations.list_roles()

    render(conn, "new.html",
      changeset: changeset,
      departments: departments,
      roles: roles,
      current_page: "users",
      layout: {AiChatWeb.Layouts, :admin}
    )
  end

  def create(conn, %{"user" => user_params}) do
    case Accounts.create_user(user_params) do
      {:ok, _user} ->
        conn
        |> put_flash(:info, "User created successfully.")
        |> redirect(to: ~p"/admin/users")

      {:error, %Ecto.Changeset{} = changeset} ->
        departments = Organizations.list_departments()
        roles = Organizations.list_roles()

        render(conn, "new.html",
          changeset: changeset,
          departments: departments,
          roles: roles,
          current_page: "users",
          layout: {AiChatWeb.Layouts, :admin}
        )
    end
  end

  def show(conn, %{"id" => id}) do
    user = Accounts.get_user!(id)
    render(conn, "show.html", user: user)
  end

  def edit(conn, %{"id" => id}) do
    user = Accounts.get_user!(id)
    changeset = Accounts.change_user(user, %{
      name: user.name,
      email: user.email,
      department_id: user.department_id,
      role_id: user.role_id,
      is_active: user.is_active
    })
    departments = Organizations.list_departments()
    roles = Organizations.list_roles()

    render(conn, "edit.html",
      user: user,
      changeset: changeset,
      departments: departments,
      roles: roles,
      current_page: "users",
      layout: {AiChatWeb.Layouts, :admin}
    )
  end

  def update(conn, %{"id" => id, "user" => user_params}) do
    user = Accounts.get_user!(id)

    case Accounts.update_user(user, user_params) do
      {:ok, _user} ->
        conn
        |> put_flash(:info, "User updated successfully.")
        |> redirect(to: ~p"/admin/users")

      {:error, %Ecto.Changeset{} = changeset} ->
        departments = Organizations.list_departments()
        roles = Organizations.list_roles()

        render(conn, "edit.html",
          user: user,
          changeset: changeset,
          departments: departments,
          roles: roles,
          current_page: "users",
          layout: {AiChatWeb.Layouts, :admin}
        )
    end
  end

  def delete(conn, %{"id" => id}) do
    user = Accounts.get_user!(id)
    {:ok, _user} = Accounts.delete_user(user)

    conn
    |> put_flash(:info, "User deleted successfully.")
    |> redirect(to: ~p"/admin/users")
  end
end
