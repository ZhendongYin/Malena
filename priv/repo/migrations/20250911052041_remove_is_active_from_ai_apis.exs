defmodule AiChat.Repo.Migrations.RemoveIsActiveFromAiApis do
  use Ecto.Migration

  def change do
    # Remove is_active field from ai_apis table
    alter table(:ai_apis) do
      remove :is_active, :boolean
    end
  end
end
