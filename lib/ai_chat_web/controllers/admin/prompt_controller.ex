defmodule AiChatWeb.Admin.PromptController do
  use AiChatWeb, :controller

  alias AiChat.Prompts
  alias AiChat.Organizations

  plug AiChatWeb.Plugs.Authorization, :manage_prompts when action in [:new, :create, :edit, :update]

  def new(conn, _params) do
    changeset = %Ecto.Changeset{data: %Prompts.Prompt{is_active: true, api_accessible: false, variables: %{}}, valid?: true, errors: []}
    departments = Organizations.list_departments()
    roles = Organizations.list_roles()

    render(conn, "new.html",
      changeset: changeset,
      departments: departments,
      roles: roles,
      current_page: "prompts",
      layout: {AiChatWeb.Layouts, :admin}
    )
  end

  def create(conn, %{"prompt" => prompt_params}) do
    # Process multi-select data
    processed_params = process_prompt_params(prompt_params)

    case Prompts.create_prompt(processed_params) do
      {:ok, _prompt} ->
        conn
        |> put_flash(:info, "Prompt created successfully.")
        |> redirect(to: ~p"/admin/prompts")

      {:error, %Ecto.Changeset{} = changeset} ->
        departments = Organizations.list_departments()
        roles = Organizations.list_roles()

        render(conn, "new.html",
          changeset: changeset,
          departments: departments,
          roles: roles,
          current_page: "prompts",
          layout: {AiChatWeb.Layouts, :admin}
        )
    end
  end

  def edit(conn, %{"id" => id}) do
    prompt = Prompts.get_prompt!(id)
    changeset = Prompts.change_prompt(prompt, %{
      title: prompt.title,
      content: prompt.content,
      department_ids: prompt.department_ids || [],
      role_ids: prompt.role_ids || [],
      is_active: prompt.is_active,
      api_accessible: prompt.api_accessible
    })
    departments = Organizations.list_departments()
    roles = Organizations.list_roles()

    render(conn, "edit.html",
      prompt: prompt,
      changeset: changeset,
      departments: departments,
      roles: roles,
      current_page: "prompts",
      layout: {AiChatWeb.Layouts, :admin}
    )
  end

  def update(conn, %{"id" => id, "prompt" => prompt_params}) do
    prompt = Prompts.get_prompt!(id)

    # Process multi-select data
    processed_params = process_prompt_params(prompt_params)

    case Prompts.update_prompt(prompt, processed_params) do
      {:ok, _prompt} ->
        conn
        |> put_flash(:info, "Prompt updated successfully.")
        |> redirect(to: ~p"/admin/prompts")

      {:error, %Ecto.Changeset{} = changeset} ->
        departments = Organizations.list_departments()
        roles = Organizations.list_roles()

        render(conn, "edit.html",
          prompt: prompt,
          changeset: changeset,
          departments: departments,
          roles: roles,
          current_page: "prompts",
          layout: {AiChatWeb.Layouts, :admin}
        )
    end
  end

  # Helper function to process multi-select form data
  defp process_prompt_params(params) do
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
