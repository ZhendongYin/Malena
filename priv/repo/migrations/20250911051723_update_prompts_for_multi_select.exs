defmodule AiChat.Repo.Migrations.UpdatePromptsForMultiSelect do
  use Ecto.Migration

  def change do
    # Add new array fields for multi-select
    alter table(:prompts) do
      add :department_ids, {:array, :integer}, default: []
      add :role_ids, {:array, :integer}, default: []
    end

    # Remove old foreign key fields
    alter table(:prompts) do
      remove :department_id, references(:departments, on_delete: :delete_all)
      remove :role_id, references(:roles, on_delete: :delete_all)
    end
  end
end
