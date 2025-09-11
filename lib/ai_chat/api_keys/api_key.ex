defmodule AiChat.ApiKeys.ApiKey do
  use Ecto.Schema
  import Ecto.Changeset
  alias AiChat.Accounts.User

  schema "api_keys" do
    field :name, :string
    field :key_hash, :string
    field :permissions, :map, default: %{}
    field :rate_limit, :integer, default: 1000
    field :requests_count, :integer, default: 0
    field :last_used_at, :utc_datetime
    field :status, :string, default: "active"
    field :expires_at, :utc_datetime

    belongs_to :user, User
    has_many :api_request_logs, AiChat.ApiKeys.ApiRequestLog

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(api_key, attrs) do
    api_key
    |> cast(attrs, [:name, :key_hash, :user_id, :permissions, :rate_limit, :requests_count, :last_used_at, :status, :expires_at])
    |> validate_required([:name, :key_hash, :user_id])
    |> validate_inclusion(:status, ["active", "suspended", "expired"])
    |> unique_constraint(:key_hash)
    |> foreign_key_constraint(:user_id)
  end

  @doc """
  Generate a new API key
  """
  def generate_key do
    :crypto.strong_rand_bytes(32) |> Base.url_encode64(padding: false)
  end

  @doc """
  Hash an API key for storage
  """
  def hash_key(key) do
    :crypto.hash(:sha256, key) |> Base.encode64()
  end

  @doc """
  Check if API key is active and not expired
  """
  def is_active?(%__MODULE__{status: "active", expires_at: nil}), do: true
  def is_active?(%__MODULE__{status: "active", expires_at: expires_at}) do
    DateTime.compare(DateTime.utc_now(), expires_at) == :lt
  end
  def is_active?(_), do: false

  @doc """
  Check if API key has a specific permission
  """
  def has_permission?(%__MODULE__{permissions: permissions}, permission) do
    get_in(permissions, [permission]) == true
  end
end
