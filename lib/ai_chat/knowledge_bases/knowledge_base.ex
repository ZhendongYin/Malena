defmodule AiChat.KnowledgeBases.KnowledgeBase do
  use Ecto.Schema
  import Ecto.Changeset

  schema "knowledge_bases" do
    field :name, :string
    field :description, :string
    field :file_path, :string
    field :file_type, :string
    field :file_size, :integer
    field :api_accessible, :boolean, default: false
    field :is_processed, :boolean, default: false
    field :processing_status, :string, default: "pending"
    field :is_active, :boolean, default: true
    field :department_ids, {:array, :integer}, default: []
    field :role_ids, {:array, :integer}, default: []

    has_many :document_chunks, AiChat.KnowledgeBases.DocumentChunk

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(knowledge_base, attrs) do
    knowledge_base
    |> cast(attrs, [:name, :description, :file_path, :file_type, :file_size, :department_ids, :role_ids, :api_accessible, :is_processed, :processing_status, :is_active])
    |> validate_required([:name, :file_path, :file_type])
    |> validate_inclusion(:file_type, ["pdf", "docx", "txt", "md"])
    |> validate_inclusion(:processing_status, ["pending", "processing", "completed", "failed"])
  end

  @doc """
  Check if knowledge base is ready for use
  """
  def is_ready?(%__MODULE__{is_processed: true, processing_status: "completed", is_active: true}), do: true
  def is_ready?(_), do: false
end
