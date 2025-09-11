defmodule AiChatWeb.Admin.KnowledgeBaseController do
  use AiChatWeb, :controller

  alias AiChat.KnowledgeBases
  alias AiChat.Organizations

  plug AiChatWeb.Plugs.Authorization, :manage_knowledge_bases when action in [:new, :create, :edit, :update]

  def new(conn, _params) do
    changeset = %Ecto.Changeset{data: %KnowledgeBases.KnowledgeBase{is_active: true, api_accessible: false, is_processed: false, processing_status: "pending"}, valid?: true, errors: []}
    departments = Organizations.list_departments()
    roles = Organizations.list_roles()

    render(conn, "new.html",
      changeset: changeset,
      departments: departments,
      roles: roles,
      current_page: "knowledge-bases",
      layout: {AiChatWeb.Layouts, :admin}
    )
  end

  def create(conn, %{"knowledge_base" => knowledge_base_params}) do
    # Process multi-select data
    processed_params = process_knowledge_base_params(knowledge_base_params)

    case KnowledgeBases.create_knowledge_base(processed_params) do
      {:ok, _knowledge_base} ->
        conn
        |> put_flash(:info, "Knowledge base created successfully.")
        |> redirect(to: ~p"/admin/knowledge-bases")

      {:error, %Ecto.Changeset{} = changeset} ->
        departments = Organizations.list_departments()
        roles = Organizations.list_roles()

        render(conn, "new.html",
          changeset: changeset,
          departments: departments,
          roles: roles,
          current_page: "knowledge-bases",
          layout: {AiChatWeb.Layouts, :admin}
        )
    end
  end

  def edit(conn, %{"id" => id}) do
    knowledge_base = KnowledgeBases.get_knowledge_base!(id)
    changeset = KnowledgeBases.change_knowledge_base(knowledge_base, %{
      name: knowledge_base.name,
      description: knowledge_base.description,
      file_path: knowledge_base.file_path,
      file_type: knowledge_base.file_type,
      department_ids: knowledge_base.department_ids || [],
      role_ids: knowledge_base.role_ids || [],
      is_active: knowledge_base.is_active,
      api_accessible: knowledge_base.api_accessible
    })
    departments = Organizations.list_departments()
    roles = Organizations.list_roles()

    render(conn, "edit.html",
      knowledge_base: knowledge_base,
      changeset: changeset,
      departments: departments,
      roles: roles,
      current_page: "knowledge-bases",
      layout: {AiChatWeb.Layouts, :admin}
    )
  end

  def update(conn, %{"id" => id, "knowledge_base" => knowledge_base_params}) do
    knowledge_base = KnowledgeBases.get_knowledge_base!(id)

    # Process multi-select data
    processed_params = process_knowledge_base_params(knowledge_base_params)

    case KnowledgeBases.update_knowledge_base(knowledge_base, processed_params) do
      {:ok, _knowledge_base} ->
        conn
        |> put_flash(:info, "Knowledge base updated successfully.")
        |> redirect(to: ~p"/admin/knowledge-bases")

      {:error, %Ecto.Changeset{} = changeset} ->
        departments = Organizations.list_departments()
        roles = Organizations.list_roles()

        render(conn, "edit.html",
          knowledge_base: knowledge_base,
          changeset: changeset,
          departments: departments,
          roles: roles,
          current_page: "knowledge-bases",
          layout: {AiChatWeb.Layouts, :admin}
        )
    end
  end

  # Helper function to process multi-select form data
  defp process_knowledge_base_params(params) do
    # Convert department_ids and role_ids from form arrays to proper format
    department_ids = case params["department_ids"] do
      nil -> []
      ids when is_list(ids) -> Enum.map(ids, &String.to_integer/1)
      _ -> []
    end

    role_ids = case params["role_ids"] do
      nil -> []
      ids when is_list(ids) -> Enum.map(ids, &String.to_integer/1)
      _ -> []
    end

    params
    |> Map.put("department_ids", department_ids)
    |> Map.put("role_ids", role_ids)
  end
end
