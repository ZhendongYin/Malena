defmodule AiChat.ApiKeys do
  @moduledoc """
  The ApiKeys context.
  """

  import Ecto.Query, warn: false
  alias AiChat.Repo
  alias AiChat.ApiKeys.ApiKey

  @doc """
  Returns the list of api_keys.

  ## Examples

      iex> list_api_keys()
      [%ApiKey{}, ...]

  """
  def list_api_keys do
    Repo.all(ApiKey)
  end

  @doc """
  Gets a single api_key.

  Raises `Ecto.NoResultsError` if the Api key does not exist.

  ## Examples

      iex> get_api_key!(123)
      %ApiKey{}

      iex> get_api_key!(456)
      ** (Ecto.NoResultsError)

  """
  def get_api_key!(id), do: Repo.get!(ApiKey, id)

  @doc """
  Creates an api_key.

  ## Examples

      iex> create_api_key(%{field: value})
      {:ok, %ApiKey{}}

      iex> create_api_key(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_api_key(attrs \\ %{}) do
    api_key = ApiKey.generate_key()
    key_hash = ApiKey.hash_key(api_key)

    %ApiKey{}
    |> ApiKey.changeset(Map.put(attrs, :key_hash, key_hash))
    |> Repo.insert()
    |> case do
      {:ok, api_key_record} -> {:ok, api_key_record, api_key}
      error -> error
    end
  end

  @doc """
  Updates an api_key.

  ## Examples

      iex> update_api_key(api_key, %{field: new_value})
      {:ok, %ApiKey{}}

      iex> update_api_key(api_key, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_api_key(%ApiKey{} = api_key, attrs) do
    api_key
    |> ApiKey.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes an api_key.

  ## Examples

      iex> delete_api_key(api_key)
      {:ok, %ApiKey{}}

      iex> delete_api_key(api_key)
      {:error, %Ecto.Changeset{}}

  """
  def delete_api_key(%ApiKey{} = api_key) do
    Repo.delete(api_key)
  end

  @doc """
  Authenticates an API key.

  ## Examples

      iex> authenticate_api_key("valid_key")
      {:ok, %ApiKey{}}

      iex> authenticate_api_key("invalid_key")
      {:error, :invalid_key}

  """
  def authenticate_api_key(api_key) do
    key_hash = ApiKey.hash_key(api_key)

    case Repo.get_by(ApiKey, key_hash: key_hash) do
      nil ->
        {:error, :invalid_key}

      api_key_record ->
        cond do
          not ApiKey.is_active?(api_key_record) ->
            {:error, :suspended}

          api_key_record.expires_at && DateTime.compare(DateTime.utc_now(), api_key_record.expires_at) == :gt ->
            {:error, :expired}

          true ->
            # Update last used timestamp
            update_api_key(api_key_record, %{last_used_at: DateTime.utc_now()})
            {:ok, api_key_record}
        end
    end
  end

  @doc """
  Increments the request count for an API key.
  """
  def increment_request_count(%ApiKey{} = api_key) do
    update_api_key(api_key, %{requests_count: api_key.requests_count + 1})
  end
end
