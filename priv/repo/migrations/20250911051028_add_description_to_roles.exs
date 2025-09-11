defmodule AiChat.Repo.Migrations.AddDescriptionToRoles do
  use Ecto.Migration

  def change do
    # Add description column to roles table
    alter table(:roles) do
      add :description, :text
    end

    # Drop the unique constraint that included department_id
    drop index(:roles, [:name, :department_id], name: :roles_name_department_id_index)

    # Remove department_id column and its foreign key constraint
    drop constraint(:roles, :roles_department_id_fkey)
    alter table(:roles) do
      remove :department_id, :bigint
    end

    # Create a new unique constraint on name only
    create unique_index(:roles, [:name])
  end
end
