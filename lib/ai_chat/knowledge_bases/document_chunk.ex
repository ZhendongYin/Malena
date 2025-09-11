defmodule AiChat.KnowledgeBases.DocumentChunk do
  use Ecto.Schema
  import Ecto.Changeset
  alias AiChat.KnowledgeBases.KnowledgeBase

  schema "document_chunks" do
    field :content, :string
    field :embedding_vector, :string
    field :chunk_index, :integer
    field :metadata, :map, default: %{}

    belongs_to :knowledge_base, KnowledgeBase

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(document_chunk, attrs) do
    document_chunk
    |> cast(attrs, [:knowledge_base_id, :content, :embedding_vector, :chunk_index, :metadata])
    |> validate_required([:knowledge_base_id, :content, :chunk_index])
    |> foreign_key_constraint(:knowledge_base_id)
  end

  @doc """
  Create a new document chunk
  """
  def create_changeset(knowledge_base_id, content, chunk_index, metadata \\ %{}) do
    changeset(%__MODULE__{}, %{
      knowledge_base_id: knowledge_base_id,
      content: content,
      chunk_index: chunk_index,
      metadata: metadata
    })
  end
end
