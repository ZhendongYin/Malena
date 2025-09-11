defmodule AiChat.Repo.Migrations.CreateApiRequestLogs do
  use Ecto.Migration

  def change do
    create table(:api_request_logs) do
      add :api_key_id, references(:api_keys, on_delete: :nilify_all)
      add :endpoint, :string, null: false
      add :method, :string, null: false
      add :status_code, :integer, null: false
      add :response_time, :integer, null: false
      add :request_body, :text
      add :response_body, :text
      add :ip_address, :string
      add :user_agent, :string
      add :error_message, :text

      timestamps(type: :utc_datetime)
    end

    create index(:api_request_logs, [:api_key_id])
    create index(:api_request_logs, [:endpoint])
    create index(:api_request_logs, [:status_code])
    create index(:api_request_logs, [:inserted_at])
  end
end
