defmodule AiChat.Repo.Migrations.CreateMessages do
  use Ecto.Migration

  def change do
    create table(:messages) do
      add :conversation_id, references(:conversations, on_delete: :delete_all), null: false
      add :role, :string, null: false
      add :content, :text, null: false
      add :metadata, :map, default: %{}, null: false
      add :is_edited, :boolean, default: false, null: false
      add :parent_message_id, references(:messages, on_delete: :nilify_all)
      add :tokens_used, :integer, default: 0, null: false

      timestamps(type: :utc_datetime)
    end

    create index(:messages, [:conversation_id])
    create index(:messages, [:role])
    create index(:messages, [:parent_message_id])
    create index(:messages, [:inserted_at])
  end
end
