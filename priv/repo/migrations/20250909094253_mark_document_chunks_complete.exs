defmodule AiChat.Repo.Migrations.MarkDocumentChunksComplete do
  use Ecto.Migration

  def change do
    # Mark the document_chunks migration as complete
    execute "INSERT INTO schema_migrations (version) VALUES ('20250909093913') ON CONFLICT DO NOTHING;"
  end
end
