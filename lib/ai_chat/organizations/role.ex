defmodule AiChat.Organizations.Role do
  use Ecto.Schema
  import Ecto.Changeset
  alias AiChat.Accounts.User

  schema "roles" do
    field :name, :string
    field :description, :string
    field :permissions, :map, default: %{}
    field :api_permissions, :map, default: %{}
    field :is_active, :boolean, default: true

    has_many :users, User
    has_many :prompts, AiChat.Prompts.Prompt
    has_many :knowledge_bases, AiChat.KnowledgeBases.KnowledgeBase
    has_many :ai_apis, AiChat.AiApis.AiApi

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(role, attrs) do
    role
    |> cast(attrs, [:name, :description, :permissions, :api_permissions, :is_active])
    |> validate_required([:name])
    |> unique_constraint(:name)
  end

  @doc """
  Check if role has a specific permission
  """
  def has_permission?(%__MODULE__{permissions: permissions}, permission) do
    get_in(permissions, [permission]) == true
  end

  @doc """
  Check if role has a specific API permission
  """
  def has_api_permission?(%__MODULE__{api_permissions: api_permissions}, permission) do
    get_in(api_permissions, [permission]) == true
  end
end
