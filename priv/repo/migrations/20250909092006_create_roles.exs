defmodule AiChat.Repo.Migrations.CreateRoles do
  use Ecto.Migration

  def change do
    create table(:roles) do
      add :name, :string, null: false
      add :department_id, references(:departments, on_delete: :delete_all), null: false
      add :permissions, :map, default: %{}, null: false
      add :api_permissions, :map, default: %{}, null: false
      add :is_active, :boolean, default: true, null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:roles, [:name, :department_id])
    create index(:roles, [:department_id])
    create index(:roles, [:is_active])
  end
end
