defmodule AiChatWeb.Admin.AiApiController do
  use AiChatWeb, :controller

  alias AiChat.AiApis
  alias AiChat.Organizations

  plug AiChatWeb.Plugs.Authorization, :manage_ai_apis when action in [:new, :create, :edit, :update]

  def new(conn, _params) do
    changeset = %Ecto.Changeset{data: %AiApis.AiApi{is_default: false, rate_limit: 100, max_tokens: 4000, temperature: 0.7, config: %{}}, valid?: true, errors: []}
    departments = Organizations.list_departments()
    roles = Organizations.list_roles()

    render(conn, "new.html",
      changeset: changeset,
      departments: departments,
      roles: roles,
      current_page: "ai-apis",
      layout: {AiChatWeb.Layouts, :admin}
    )
  end

  def create(conn, %{"ai_api" => ai_api_params}) do
    # Process the parameters to handle default API logic
    processed_params = process_ai_api_params(ai_api_params)

    case AiApis.create_ai_api(processed_params) do
      {:ok, _ai_api} ->
        conn
        |> put_flash(:info, "AI API created successfully.")
        |> redirect(to: ~p"/admin/ai-apis")

      {:error, %Ecto.Changeset{} = changeset} ->
        departments = Organizations.list_departments()
        roles = Organizations.list_roles()

        render(conn, "new.html",
          changeset: changeset,
          departments: departments,
          roles: roles,
          current_page: "ai-apis",
          layout: {AiChatWeb.Layouts, :admin}
        )
    end
  end

  def edit(conn, %{"id" => id}) do
    ai_api = AiApis.get_ai_api!(id)
    changeset = AiApis.change_ai_api(ai_api, %{
      name: ai_api.name,
      provider: ai_api.provider,
      base_url: ai_api.base_url,
      model_name: ai_api.model_name,
      department_id: ai_api.department_id,
      role_id: ai_api.role_id,
      is_default: ai_api.is_default,
      rate_limit: ai_api.rate_limit,
      max_tokens: ai_api.max_tokens,
      temperature: ai_api.temperature
    })
    departments = Organizations.list_departments()
    roles = Organizations.list_roles()

    render(conn, "edit.html",
      ai_api: ai_api,
      changeset: changeset,
      departments: departments,
      roles: roles,
      current_page: "ai-apis",
      layout: {AiChatWeb.Layouts, :admin}
    )
  end

  def update(conn, %{"id" => id, "ai_api" => ai_api_params}) do
    ai_api = AiApis.get_ai_api!(id)

    # Process the parameters to handle default API logic
    processed_params = process_ai_api_params(ai_api_params)

    case AiApis.update_ai_api(ai_api, processed_params) do
      {:ok, _ai_api} ->
        conn
        |> put_flash(:info, "AI API updated successfully.")
        |> redirect(to: ~p"/admin/ai-apis")

      {:error, %Ecto.Changeset{} = changeset} ->
        departments = Organizations.list_departments()
        roles = Organizations.list_roles()

        render(conn, "edit.html",
          ai_api: ai_api,
          changeset: changeset,
          departments: departments,
          roles: roles,
          current_page: "ai-apis",
          layout: {AiChatWeb.Layouts, :admin}
        )
    end
  end

  # Helper function to process AI API parameters
  defp process_ai_api_params(params) do
    # Handle default API logic - if setting as default, unset all others first
    if params["is_default"] == "true" or params["is_default"] == true do
      # This will be handled by the AiApis context
      params
    else
      params
    end
  end
end
