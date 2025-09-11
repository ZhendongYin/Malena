defmodule AiChat.Repo.Migrations.RemoveMissingMigration do
  use Ecto.Migration

  def change do
    # Remove the missing migration record from schema_migrations
    execute "DELETE FROM schema_migrations WHERE version = '20250909092017';"
  end
end
