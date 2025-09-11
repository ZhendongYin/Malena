defmodule AiChat.Repo.Migrations.CreateAiApis do
  use Ecto.Migration

  def change do
    create table(:ai_apis) do
      add :name, :string, null: false
      add :provider, :string, null: false
      add :api_key, :string, null: false
      add :base_url, :string
      add :model_name, :string, null: false
      add :department_id, references(:departments, on_delete: :nilify_all)
      add :role_id, references(:roles, on_delete: :nilify_all)
      add :is_active, :boolean, default: true, null: false
      add :rate_limit, :integer, default: 100, null: false
      add :max_tokens, :integer, default: 4000, null: false
      add :temperature, :float, default: 0.7, null: false
      add :config, :map, default: %{}, null: false

      timestamps(type: :utc_datetime)
    end

    create index(:ai_apis, [:provider])
    create index(:ai_apis, [:department_id])
    create index(:ai_apis, [:role_id])
    create index(:ai_apis, [:is_active])
  end
end
