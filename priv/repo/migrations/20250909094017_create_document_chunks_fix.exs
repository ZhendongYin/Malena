defmodule AiChat.Repo.Migrations.CreateDocumentChunksFix do
  use Ecto.Migration

  def change do
    # This migration is just to fix the missing migration record
    # The table already exists, so we do nothing
  end
end
