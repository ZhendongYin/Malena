defmodule AiChat.Repo.Migrations.AddDeletedAtToConversations do
  use Ecto.Migration

  def change do
    alter table(:conversations) do
      add :deleted_at, :utc_datetime, null: true
    end

    # Add index for better query performance
    create index(:conversations, [:deleted_at])
  end
end
