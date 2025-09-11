defmodule AiChat.Repo.Migrations.CreateUsers do
  use Ecto.Migration

  def change do
    create table(:users) do
      add :name, :string, null: false
      add :email, :string, null: false
      add :encrypted_password, :string, null: false
      add :department_id, references(:departments, on_delete: :nilify_all)
      add :role_id, references(:roles, on_delete: :nilify_all)
      add :avatar_url, :string
      add :is_active, :boolean, default: true, null: false
      add :last_login_at, :utc_datetime

      timestamps(type: :utc_datetime)
    end

    create unique_index(:users, [:email])
    create index(:users, [:department_id])
    create index(:users, [:role_id])
    create index(:users, [:is_active])
  end
end
