defmodule AiChat.Repo.Migrations.CreateDepartments do
  use Ecto.Migration

  def change do
    create table(:departments) do
      add :name, :string, null: false
      add :description, :text
      add :parent_id, references(:departments, on_delete: :nilify_all)
      add :api_access_enabled, :boolean, default: false, null: false
      add :is_active, :boolean, default: true, null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:departments, [:name])
    create index(:departments, [:parent_id])
    create index(:departments, [:is_active])
  end
end
