defmodule AiChat.Chat.Message do
  use Ecto.Schema
  import Ecto.Changeset
  alias AiChat.Chat.Conversation

  schema "messages" do
    field :role, :string
    field :content, :string
    field :metadata, :map, default: %{}
    field :is_edited, :boolean, default: false
    field :tokens_used, :integer, default: 0

    belongs_to :conversation, Conversation
    belongs_to :parent_message, __MODULE__
    has_many :child_messages, __MODULE__, foreign_key: :parent_message_id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(message, attrs) do
    message
    |> cast(attrs, [:conversation_id, :role, :content, :metadata, :is_edited, :parent_message_id, :tokens_used])
    |> validate_required([:conversation_id, :role, :content])
    |> validate_inclusion(:role, ["user", "assistant", "system"])
    |> foreign_key_constraint(:conversation_id)
    |> foreign_key_constraint(:parent_message_id)
  end

  @doc """
  Create a new user message
  """
  def user_message_changeset(conversation_id, content) do
    changeset(%__MODULE__{}, %{
      conversation_id: conversation_id,
      role: "user",
      content: content
    })
  end

  @doc """
  Create a new assistant message
  """
  def assistant_message_changeset(conversation_id, content, metadata \\ %{}) do
    changeset(%__MODULE__{}, %{
      conversation_id: conversation_id,
      role: "assistant",
      content: content,
      metadata: metadata
    })
  end

  @doc """
  Create a new system message
  """
  def system_message_changeset(conversation_id, content) do
    changeset(%__MODULE__{}, %{
      conversation_id: conversation_id,
      role: "system",
      content: content
    })
  end
end
