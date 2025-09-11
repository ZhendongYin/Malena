defmodule AiChat.Organizations.Department do
  use Ecto.Schema
  import Ecto.Changeset
  alias AiChat.Accounts.User

  schema "departments" do
    field :name, :string
    field :description, :string
    field :api_access_enabled, :boolean, default: false
    field :is_active, :boolean, default: true

    belongs_to :parent, __MODULE__
    has_many :children, __MODULE__, foreign_key: :parent_id
    has_many :users, User
    has_many :prompts, AiChat.Prompts.Prompt
    has_many :knowledge_bases, AiChat.KnowledgeBases.KnowledgeBase
    has_many :ai_apis, AiChat.AiApis.AiApi

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(department, attrs) do
    department
    |> cast(attrs, [:name, :description, :parent_id, :api_access_enabled, :is_active])
    |> validate_required([:name])
    |> unique_constraint(:name)
    |> foreign_key_constraint(:parent_id)
  end
end
