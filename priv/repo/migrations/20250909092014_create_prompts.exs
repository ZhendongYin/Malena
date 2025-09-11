defmodule AiChat.Repo.Migrations.CreatePrompts do
  use Ecto.Migration

  def change do
    create table(:prompts) do
      add :title, :string, null: false
      add :content, :text, null: false
      add :variables, :map, default: %{}, null: false
      add :department_id, references(:departments, on_delete: :nilify_all)
      add :role_id, references(:roles, on_delete: :nilify_all)
      add :is_active, :boolean, default: true, null: false
      add :api_accessible, :boolean, default: false, null: false
      add :version, :integer, default: 1, null: false

      timestamps(type: :utc_datetime)
    end

    create index(:prompts, [:department_id])
    create index(:prompts, [:role_id])
    create index(:prompts, [:is_active])
    create index(:prompts, [:api_accessible])
  end
end
