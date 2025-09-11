defmodule AiChat.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset
  alias AiChat.Organizations.{Department, Role}
  alias AiChat.ApiKeys.ApiKey

  schema "users" do
    field :name, :string
    field :email, :string
    field :encrypted_password, :string
    field :password, :string, virtual: true
    field :avatar_url, :string
    field :is_active, :boolean, default: true
    field :last_login_at, :utc_datetime

    belongs_to :department, Department
    belongs_to :role, Role
    belongs_to :preferred_ai_api, AiChat.AiApis.AiApi
    has_many :api_keys, ApiKey
    has_many :conversations, AiChat.Chat.Conversation

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:name, :email, :password, :avatar_url, :is_active, :last_login_at, :department_id, :role_id, :preferred_ai_api_id])
    |> validate_required([:name, :email])
    |> validate_format(:email, ~r/^[^\s]+@[^\s]+\.[^\s]+$/, message: "must be a valid email")
    |> unique_constraint(:email)
    |> foreign_key_constraint(:department_id)
    |> foreign_key_constraint(:role_id)
    |> put_password_hash()
  end

  @doc false
  def registration_changeset(user, attrs) do
    user
    |> cast(attrs, [:name, :email, :password, :department_id, :role_id, :preferred_ai_api_id])
    |> validate_required([:name, :email, :password])
    |> validate_format(:email, ~r/^[^\s]+@[^\s]+\.[^\s]+$/, message: "must be a valid email")
    |> validate_length(:password, min: 8, message: "must be at least 8 characters")
    |> unique_constraint(:email)
    |> foreign_key_constraint(:department_id)
    |> foreign_key_constraint(:role_id)
    |> put_password_hash()
  end

  defp put_password_hash(changeset) do
    case changeset do
      %Ecto.Changeset{valid?: true, changes: %{password: password}} when password != "" ->
        put_change(changeset, :encrypted_password, Bcrypt.hash_pwd_salt(password))
      _ ->
        changeset
    end
  end
end
