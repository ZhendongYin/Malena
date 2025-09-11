defmodule AiChatWeb.Admin.RoleController do
  use AiChatWeb, :controller

  alias AiChat.Organizations

  plug AiChatWeb.Plugs.Authorization, "manage_roles" when action in [:new, :create, :edit, :update]

  def new(conn, _params) do
    changeset = %Ecto.Changeset{data: %Organizations.Role{is_active: true, permissions: %{}, api_permissions: %{}}, valid?: true, errors: []}

    render(conn, "new.html",
      changeset: changeset,
      current_page: "roles",
      layout: {AiChatWeb.Layouts, :admin}
    )
  end

  def create(conn, %{"role" => role_params}) do
    # Process permissions from form data
    processed_params = process_role_params(role_params)

    case Organizations.create_role(processed_params) do
      {:ok, _role} ->
        conn
        |> put_flash(:info, "Role created successfully.")
        |> redirect(to: ~p"/admin/roles")

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "new.html",
          changeset: changeset,
          current_page: "roles",
          layout: {AiChatWeb.Layouts, :admin}
        )
    end
  end

  def edit(conn, %{"id" => id}) do
    role = Organizations.get_role!(id)
    changeset = Organizations.change_role(role, %{
      name: role.name,
      description: role.description,
      permissions: role.permissions,
      api_permissions: role.api_permissions,
      is_active: role.is_active
    })

    # Check for associations
    has_users = check_role_has_users(role)
    has_prompts = check_role_has_prompts(role)
    has_knowledge_bases = check_role_has_knowledge_bases(role)

    render(conn, "edit.html",
      role: role,
      changeset: changeset,
      has_users: has_users,
      has_prompts: has_prompts,
      has_knowledge_bases: has_knowledge_bases,
      current_page: "roles",
      layout: {AiChatWeb.Layouts, :admin}
    )
  end

  def update(conn, %{"id" => id, "role" => role_params}) do
    role = Organizations.get_role!(id)

    # Process permissions from form data
    processed_params = process_role_params(role_params)

    case Organizations.update_role(role, processed_params) do
      {:ok, _role} ->
        conn
        |> put_flash(:info, "Role updated successfully.")
        |> redirect(to: ~p"/admin/roles")

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "edit.html",
          role: role,
          changeset: changeset,
          current_page: "roles",
          layout: {AiChatWeb.Layouts, :admin}
        )
    end
  end

  # Helper function to process role parameters
  defp process_role_params(params) do
    permissions = params["permissions"] || %{}

    # Convert permissions to boolean map
    processed_permissions =
      permissions
      |> Enum.map(fn {key, value} -> {key, value == "true"} end)
      |> Enum.into(%{})

    params
    |> Map.put("permissions", processed_permissions)
    |> Map.delete("permissions")
    |> Map.put("permissions", processed_permissions)
  end

  # Check if role has associated users
  defp check_role_has_users(role) do
    import Ecto.Query
    from(u in AiChat.Accounts.User, where: u.role_id == ^role.id, limit: 1)
    |> AiChat.Repo.exists?()
  end

  # Check if role has associated prompts
  defp check_role_has_prompts(role) do
    import Ecto.Query
    from(p in AiChat.Prompts.Prompt, where: ^role.id in p.role_ids, limit: 1)
    |> AiChat.Repo.exists?()
  end

  # Check if role has associated knowledge bases
  defp check_role_has_knowledge_bases(role) do
    import Ecto.Query
    from(k in AiChat.KnowledgeBases.KnowledgeBase, where: ^role.id in k.role_ids, limit: 1)
    |> AiChat.Repo.exists?()
  end
end
