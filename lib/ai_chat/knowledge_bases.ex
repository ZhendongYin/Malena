defmodule AiChat.KnowledgeBases do
  @moduledoc """
  The KnowledgeBases context.
  """

  import Ecto.Query, warn: false
  alias AiChat.Repo
  alias AiChat.KnowledgeBases.KnowledgeBase

  @doc """
  Returns the list of knowledge_bases.

  ## Examples

      iex> list_knowledge_bases()
      [%KnowledgeBase{}, ...]

  """
  def list_knowledge_bases do
    Repo.all(KnowledgeBase)
  end

  @doc """
  Gets a single knowledge_base.

  Raises `Ecto.NoResultsError` if the Knowledge base does not exist.

  ## Examples

      iex> get_knowledge_base!(123)
      %KnowledgeBase{}

      iex> get_knowledge_base!(456)
      ** (Ecto.NoResultsError)

  """
  def get_knowledge_base!(id), do: Repo.get!(KnowledgeBase, id)

  @doc """
  Creates a knowledge_base.

  ## Examples

      iex> create_knowledge_base(%{field: value})
      {:ok, %KnowledgeBase{}}

      iex> create_knowledge_base(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_knowledge_base(attrs \\ %{}) do
    %KnowledgeBase{}
    |> KnowledgeBase.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a knowledge_base.

  ## Examples

      iex> update_knowledge_base(knowledge_base, %{field: new_value})
      {:ok, %KnowledgeBase{}}

      iex> update_knowledge_base(knowledge_base, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_knowledge_base(%KnowledgeBase{} = knowledge_base, attrs) do
    knowledge_base
    |> KnowledgeBase.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a knowledge_base.

  ## Examples

      iex> delete_knowledge_base(knowledge_base)
      {:ok, %KnowledgeBase{}}

      iex> delete_knowledge_base(knowledge_base)
      {:error, %Ecto.Changeset{}}

  """
  def delete_knowledge_base(%KnowledgeBase{} = knowledge_base) do
    Repo.delete(knowledge_base)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking knowledge_base changes.

  ## Examples

      iex> change_knowledge_base(knowledge_base)
      %Ecto.Changeset{data: %KnowledgeBase{}}

  """
  def change_knowledge_base(%KnowledgeBase{} = knowledge_base, attrs \\ %{}) do
    KnowledgeBase.changeset(knowledge_base, attrs)
  end

  @doc """
  Get knowledge bases for a specific department and role.
  """
  def get_knowledge_bases_for_user(user) do
    from(kb in KnowledgeBase,
      where: kb.is_active == true and
             (^user.department_id in kb.department_ids or kb.department_ids == []) and
             (^user.role_id in kb.role_ids or kb.role_ids == [])
    )
    |> Repo.all()
  end

  @doc """
  Search knowledge base chunks by similarity to user message.
  """
  def search_knowledge_base_chunks(user_message, user, limit \\ 5) do
    # Get user's accessible knowledge bases
    knowledge_bases = get_knowledge_bases_for_user(user)

    if Enum.empty?(knowledge_bases) do
      []
    else
      # For now, we'll do a simple text search
      # In a real implementation, you'd use vector similarity search with pgvector
      knowledge_base_ids = Enum.map(knowledge_bases, & &1.id)

      from(dc in AiChat.KnowledgeBases.DocumentChunk,
        join: kb in KnowledgeBase, on: dc.knowledge_base_id == kb.id,
        where: dc.knowledge_base_id in ^knowledge_base_ids and
               (fragment("? ILIKE ?", dc.content, ^"%#{user_message}%") or
                fragment("? ILIKE ?", dc.metadata, ^"%#{user_message}%")),
        order_by: [desc: dc.inserted_at],
        limit: ^limit,
        select: %{
          content: dc.content,
          metadata: dc.metadata,
          knowledge_base_name: kb.name
        }
      )
      |> Repo.all()
    end
  end
end
