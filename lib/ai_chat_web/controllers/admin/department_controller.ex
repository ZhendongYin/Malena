defmodule AiChatWeb.Admin.DepartmentController do
  use AiChatWeb, :controller

  alias AiChat.Organizations

  plug AiChatWeb.Plugs.Authorization, "manage_departments" when action in [:new, :create, :edit, :update]

  def new(conn, _params) do
    changeset = %Ecto.Changeset{data: %Organizations.Department{is_active: true, api_access_enabled: false}, valid?: true, errors: []}
    departments = Organizations.list_departments()

    render(conn, "new.html",
      changeset: changeset,
      departments: departments,
      current_page: "departments",
      layout: {AiChatWeb.Layouts, :admin}
    )
  end

  def create(conn, %{"department" => department_params}) do
    case Organizations.create_department(department_params) do
      {:ok, _department} ->
        conn
        |> put_flash(:info, "Department created successfully.")
        |> redirect(to: ~p"/admin/departments")

      {:error, %Ecto.Changeset{} = changeset} ->
        departments = Organizations.list_departments()

        render(conn, "new.html",
          changeset: changeset,
          departments: departments,
          current_page: "departments",
          layout: {AiChatWeb.Layouts, :admin}
        )
    end
  end

  def edit(conn, %{"id" => id}) do
    department = Organizations.get_department!(id)
    changeset = Organizations.change_department(department, %{
      name: department.name,
      description: department.description,
      parent_id: department.parent_id,
      api_access_enabled: department.api_access_enabled,
      is_active: department.is_active
    })
    departments = Organizations.list_departments()

    # Check for associations
    has_users = check_department_has_users(department)
    has_prompts = check_department_has_prompts(department)
    has_knowledge_bases = check_department_has_knowledge_bases(department)
    has_child_departments = check_department_has_child_departments(department)

    render(conn, "edit.html",
      department: department,
      changeset: changeset,
      departments: departments,
      has_users: has_users,
      has_prompts: has_prompts,
      has_knowledge_bases: has_knowledge_bases,
      has_child_departments: has_child_departments,
      current_page: "departments",
      layout: {AiChatWeb.Layouts, :admin}
    )
  end

  def update(conn, %{"id" => id, "department" => department_params}) do
    department = Organizations.get_department!(id)

    case Organizations.update_department(department, department_params) do
      {:ok, _department} ->
        conn
        |> put_flash(:info, "Department updated successfully.")
        |> redirect(to: ~p"/admin/departments")

      {:error, %Ecto.Changeset{} = changeset} ->
        departments = Organizations.list_departments()

        render(conn, "edit.html",
          department: department,
          changeset: changeset,
          departments: departments,
          current_page: "departments",
          layout: {AiChatWeb.Layouts, :admin}
        )
    end
  end

  # Check if department has associated users
  defp check_department_has_users(department) do
    import Ecto.Query
    from(u in AiChat.Accounts.User, where: u.department_id == ^department.id, limit: 1)
    |> AiChat.Repo.exists?()
  end

  # Check if department has associated prompts
  defp check_department_has_prompts(department) do
    import Ecto.Query
    from(p in AiChat.Prompts.Prompt, where: ^department.id in p.department_ids, limit: 1)
    |> AiChat.Repo.exists?()
  end

  # Check if department has associated knowledge bases
  defp check_department_has_knowledge_bases(department) do
    import Ecto.Query
    from(k in AiChat.KnowledgeBases.KnowledgeBase, where: ^department.id in k.department_ids, limit: 1)
    |> AiChat.Repo.exists?()
  end

  # Check if department has child departments
  defp check_department_has_child_departments(department) do
    import Ecto.Query
    from(d in AiChat.Organizations.Department, where: d.parent_id == ^department.id, limit: 1)
    |> AiChat.Repo.exists?()
  end
end
