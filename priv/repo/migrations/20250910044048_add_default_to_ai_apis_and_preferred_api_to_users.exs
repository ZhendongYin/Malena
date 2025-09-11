defmodule AiChat.Repo.Migrations.AddDefaultToAiApisAndPreferredApiToUsers do
  use Ecto.Migration

  def change do
    # Add is_default field to ai_apis table
    alter table(:ai_apis) do
      add :is_default, :boolean, default: false, null: false
    end

    # Add preferred_ai_api_id field to users table
    alter table(:users) do
      add :preferred_ai_api_id, references(:ai_apis, on_delete: :nilify_all)
    end

    # Create index for better performance
    create index(:users, [:preferred_ai_api_id])
    create index(:ai_apis, [:is_default])
  end
end
