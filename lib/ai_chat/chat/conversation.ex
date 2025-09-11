defmodule AiChat.Chat.Conversation do
  use Ecto.Schema
  import Ecto.Changeset
  alias AiChat.Accounts.User

  schema "conversations" do
    field :title, :string
    field :is_shared, :boolean, default: false
    field :share_token, :string
    field :metadata, :map, default: %{}
    field :deleted_at, :utc_datetime

    belongs_to :user, User
    has_many :messages, AiChat.Chat.Message

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(conversation, attrs) do
    conversation
    |> cast(attrs, [:user_id, :title, :is_shared, :share_token, :metadata, :deleted_at])
    |> validate_required([:user_id])
    |> unique_constraint(:share_token)
    |> foreign_key_constraint(:user_id)
  end

  @doc """
  Generate a unique share token for the conversation
  """
  def generate_share_token do
    :crypto.strong_rand_bytes(16) |> Base.url_encode64(padding: false)
  end
end
