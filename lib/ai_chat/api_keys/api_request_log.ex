defmodule AiChat.ApiKeys.ApiRequestLog do
  use Ecto.Schema
  import Ecto.Changeset
  alias AiChat.ApiKeys.ApiKey

  schema "api_request_logs" do
    field :endpoint, :string
    field :method, :string
    field :status_code, :integer
    field :response_time, :integer
    field :request_body, :string
    field :response_body, :string
    field :ip_address, :string
    field :user_agent, :string
    field :error_message, :string

    belongs_to :api_key, ApiKey

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(api_request_log, attrs) do
    api_request_log
    |> cast(attrs, [:api_key_id, :endpoint, :method, :status_code, :response_time, :request_body, :response_body, :ip_address, :user_agent, :error_message])
    |> validate_required([:endpoint, :method, :status_code, :response_time])
    |> foreign_key_constraint(:api_key_id)
  end
end
