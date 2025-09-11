defmodule AiChat.Repo.Migrations.AllowNullApiKeyForOllama do
  use Ecto.Migration

  def change do
    # Allow api_key to be null for Ollama provider
    alter table(:ai_apis) do
      modify :api_key, :string, null: true
    end
  end
end
