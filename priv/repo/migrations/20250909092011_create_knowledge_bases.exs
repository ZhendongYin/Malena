defmodule AiChat.Repo.Migrations.CreateKnowledgeBases do
  use Ecto.Migration

  def change do
    create table(:knowledge_bases) do
      add :name, :string, null: false
      add :description, :text
      add :file_path, :string, null: false
      add :file_type, :string, null: false
      add :file_size, :integer
      add :department_id, references(:departments, on_delete: :nilify_all)
      add :role_id, references(:roles, on_delete: :nilify_all)
      add :api_accessible, :boolean, default: false, null: false
      add :is_processed, :boolean, default: false, null: false
      add :processing_status, :string, default: "pending"
      add :is_active, :boolean, default: true, null: false

      timestamps(type: :utc_datetime)
    end

    create index(:knowledge_bases, [:department_id])
    create index(:knowledge_bases, [:role_id])
    create index(:knowledge_bases, [:api_accessible])
    create index(:knowledge_bases, [:is_processed])
    create index(:knowledge_bases, [:is_active])
  end
end
