defmodule AiChat.Repo.Migrations.CreateApiKeys do
  use Ecto.Migration

  def change do
    create table(:api_keys) do
      add :name, :string, null: false
      add :key_hash, :string, null: false
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :permissions, :map, default: %{}, null: false
      add :rate_limit, :integer, default: 1000, null: false
      add :requests_count, :integer, default: 0, null: false
      add :last_used_at, :utc_datetime
      add :status, :string, default: "active", null: false
      add :expires_at, :utc_datetime

      timestamps(type: :utc_datetime)
    end

    create unique_index(:api_keys, [:key_hash])
    create index(:api_keys, [:user_id])
    create index(:api_keys, [:status])
    create index(:api_keys, [:last_used_at])
  end
end
