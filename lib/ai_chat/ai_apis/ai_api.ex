defmodule AiChat.AiApis.AiApi do
  use Ecto.Schema
  import Ecto.Changeset
  alias AiChat.Organizations.{Department, Role}

  schema "ai_apis" do
    field :name, :string
    field :provider, :string
    field :api_key, :string
    field :base_url, :string
    field :model_name, :string
    field :is_default, :boolean, default: false
    field :rate_limit, :integer, default: 100
    field :max_tokens, :integer, default: 4000
    field :temperature, :float, default: 0.7
    field :config, :map, default: %{}

    belongs_to :department, Department
    belongs_to :role, Role

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(ai_api, attrs) do
    ai_api
    |> cast(attrs, [:name, :provider, :api_key, :base_url, :model_name, :department_id, :role_id, :is_default, :rate_limit, :max_tokens, :temperature, :config])
    |> validate_required([:name, :provider, :model_name])
    |> validate_inclusion(:provider, ["openai", "claude", "gemini", "ollama"])
    |> validate_api_key_requirement()
    |> validate_number(:rate_limit, greater_than: 0)
    |> validate_number(:max_tokens, greater_than: 0)
    |> validate_number(:temperature, greater_than_or_equal_to: 0.0, less_than_or_equal_to: 2.0)
    |> foreign_key_constraint(:department_id)
    |> foreign_key_constraint(:role_id)
  end

  @doc false
  def update_changeset(ai_api, attrs) do
    # For updates, allow empty api_key to keep current value
    processed_attrs = if attrs["api_key"] == "" or attrs[:api_key] == "" do
      Map.delete(attrs, "api_key") |> Map.delete(:api_key)
    else
      attrs
    end

    ai_api
    |> cast(processed_attrs, [:name, :provider, :api_key, :base_url, :model_name, :department_id, :role_id, :is_default, :rate_limit, :max_tokens, :temperature, :config])
    |> validate_required([:name, :provider, :model_name])
    |> validate_inclusion(:provider, ["openai", "claude", "gemini", "ollama"])
    |> validate_api_key_requirement_for_update()
    |> validate_number(:rate_limit, greater_than: 0)
    |> validate_number(:max_tokens, greater_than: 0)
    |> validate_number(:temperature, greater_than_or_equal_to: 0.0, less_than_or_equal_to: 2.0)
    |> foreign_key_constraint(:department_id)
    |> foreign_key_constraint(:role_id)
  end

  # Custom validation for API key requirement
  defp validate_api_key_requirement(changeset) do
    provider = get_field(changeset, :provider)

    case provider do
      "ollama" ->
        # Ollama doesn't require API key
        changeset
      _ ->
        # Other providers require API key
        validate_required(changeset, [:api_key])
    end
  end

  # Custom validation for API key requirement during updates
  defp validate_api_key_requirement_for_update(changeset) do
    provider = get_field(changeset, :provider)
    api_key = get_field(changeset, :api_key)

    case provider do
      "ollama" ->
        # Ollama doesn't require API key
        changeset
      _ ->
        # For updates, only validate if api_key is being changed (not nil/empty)
        if api_key && api_key != "" do
          changeset
        else
          # If api_key is nil/empty, it means keep current value, so no validation needed
          changeset
        end
    end
  end

  @doc """
  Check if AI API is available for use
  """
  def is_available?(%__MODULE__{}), do: true

  @doc """
  Get the base URL for the API provider
  """
  def get_base_url(%__MODULE__{base_url: base_url}) when not is_nil(base_url), do: base_url
  def get_base_url(%__MODULE__{provider: "openai"}), do: "https://api.openai.com/v1"
  def get_base_url(%__MODULE__{provider: "claude"}), do: "https://api.anthropic.com/v1"
  def get_base_url(%__MODULE__{provider: "gemini"}), do: "https://generativelanguage.googleapis.com/v1"
  def get_base_url(%__MODULE__{provider: "ollama"}), do: "http://localhost:11434/v1"
  def get_base_url(_), do: nil
end
