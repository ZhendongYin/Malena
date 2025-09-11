defmodule AiChat.AiApis do
  @moduledoc """
  The AiApis context.
  """

  import Ecto.Query, warn: false
  alias AiChat.Repo
  alias AiChat.AiApis.AiApi

  @doc """
  Returns the list of ai_apis.

  ## Examples

      iex> list_ai_apis()
      [%AiApi{}, ...]

  """
  def list_ai_apis do
    Repo.all(AiApi)
  end

  @doc """
  Gets a single ai_api.

  Raises `Ecto.NoResultsError` if the Ai api does not exist.

  ## Examples

      iex> get_ai_api!(123)
      %AiApi{}

      iex> get_ai_api!(456)
      ** (Ecto.NoResultsError)

  """
  def get_ai_api!(id), do: Repo.get!(AiApi, id)

  @doc """
  Creates an ai_api.

  ## Examples

      iex> create_ai_api(%{field: value})
      {:ok, %AiApi{}}

      iex> create_ai_api(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_ai_api(attrs \\ %{}) do
    # For Ollama, allow empty api_key
    processed_attrs = if attrs["provider"] == "ollama" and (attrs["api_key"] == "" or attrs["api_key"] == nil) do
      Map.put(attrs, "api_key", nil)
    else
      attrs
    end

    # Handle default API setting
    is_default = processed_attrs["is_default"] == "true" or processed_attrs["is_default"] == true

    Repo.transaction(fn ->
      # If setting as default, first unset all other defaults
      if is_default do
        from(a in AiApi, update: [set: [is_default: false]])
        |> Repo.update_all([])
      end

      # Create the new API
      case %AiApi{}
           |> AiApi.changeset(processed_attrs)
           |> Repo.insert() do
        {:ok, ai_api} -> ai_api
        {:error, changeset} -> Repo.rollback(changeset)
      end
    end)
  end

  @doc """
  Updates an ai_api.

  ## Examples

      iex> update_ai_api(ai_api, %{field: new_value})
      {:ok, %AiApi{}}

      iex> update_ai_api(ai_api, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_ai_api(%AiApi{} = ai_api, attrs) do
    # Handle default API setting
    is_default = attrs["is_default"] == "true" or attrs["is_default"] == true

    Repo.transaction(fn ->
      # If setting as default, first unset all other defaults
      if is_default do
        from(a in AiApi, where: a.id != ^ai_api.id)
        |> Repo.update_all(set: [is_default: false])
      end

      # Update the API
      case ai_api
           |> AiApi.update_changeset(attrs)
           |> Repo.update() do
        {:ok, updated_api} -> updated_api
        {:error, changeset} -> Repo.rollback(changeset)
      end
    end)
  end

  @doc """
  Sets an AI API as default, ensuring only one API can be default at a time.
  """
  def set_default_ai_api(%AiApi{} = ai_api) do
    Repo.transaction(fn ->
      # First, unset all other default APIs
      from(a in AiApi, where: a.id != ^ai_api.id)
      |> Repo.update_all(set: [is_default: false])

      # Then set the selected API as default
      case update_ai_api(ai_api, %{is_default: true}) do
        {:ok, updated_api} -> updated_api
        {:error, changeset} -> Repo.rollback(changeset)
      end
    end)
  end

  @doc """
  Deletes an ai_api.

  ## Examples

      iex> delete_ai_api(ai_api)
      {:ok, %AiApi{}}

      iex> delete_ai_api(ai_api)
      {:error, %Ecto.Changeset{}}

  """
  def delete_ai_api(%AiApi{} = ai_api) do
    Repo.delete(ai_api)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking ai_api changes.

  ## Examples

      iex> change_ai_api(ai_api)
      %Ecto.Changeset{data: %AiApi{}}

  """
  def change_ai_api(%AiApi{} = ai_api, attrs \\ %{}) do
    AiApi.changeset(ai_api, attrs)
  end

  @doc """
  Get AI APIs available for a specific user.
  """
  def get_ai_apis_for_user(user) do
    from(a in AiApi,
      where: (a.department_id == ^user.department_id or is_nil(a.department_id)) and
             (a.role_id == ^user.role_id or is_nil(a.role_id))
    )
    |> Repo.all()
  end

  @doc """
  Get the AI API that should be used for a specific user.
  Priority: 1. User's preferred API, 2. Default API for user's context, 3. Any available API
  """
  def get_ai_api_for_user(user) do
    # First, try to get user's preferred API if it exists and is available
    if user.preferred_ai_api_id do
      case get_ai_api!(user.preferred_ai_api_id) do
        api when not is_nil(api) ->
          if is_available_for_user?(api, user) do
            api
          else
            get_fallback_ai_api(user)
          end
        _ ->
          get_fallback_ai_api(user)
      end
    else
      get_fallback_ai_api(user)
    end
  end

  @doc """
  Get the default AI API for a user's department and role.
  """
  def get_default_ai_api_for_user(user) do
    query = from(a in AiApi,
      where: a.is_default == true and
             (a.department_id == ^user.department_id or is_nil(a.department_id))
    )

    # Add role condition only if user has a role
    query = if user.role_id do
      where(query, [a], a.role_id == ^user.role_id or is_nil(a.role_id))
    else
      where(query, [a], is_nil(a.role_id))
    end

    query
    |> order_by([a], [asc: a.department_id, asc: a.role_id])
    |> limit(1)
    |> Repo.one()
  end

  @doc """
  Get any available AI API for a user as fallback.
  """
  def get_any_available_ai_api_for_user(user) do
    query = from(a in AiApi,
      where: (a.department_id == ^user.department_id or is_nil(a.department_id))
    )

    # Add role condition only if user has a role
    query = if user.role_id do
      where(query, [a], a.role_id == ^user.role_id or is_nil(a.role_id))
    else
      where(query, [a], is_nil(a.role_id))
    end

    query
    |> order_by([a], [asc: a.department_id, asc: a.role_id])
    |> limit(1)
    |> Repo.one()
  end

  # Private helper functions
  defp get_fallback_ai_api(user) do
    # Try default API first
    case get_default_ai_api_for_user(user) do
      nil -> get_any_available_ai_api_for_user(user)
      api -> api
    end
  end

  defp is_available_for_user?(api, user) do
    (is_nil(api.department_id) or api.department_id == user.department_id) and
    (is_nil(api.role_id) or api.role_id == user.role_id)
  end
end
