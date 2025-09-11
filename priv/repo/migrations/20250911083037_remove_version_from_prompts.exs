defmodule AiChat.Repo.Migrations.RemoveVersionFromPrompts do
  use Ecto.Migration

  def change do
    alter table(:prompts) do
      remove :version, :integer
    end
  end
end
