defmodule AiChat.Prompts.Prompt do
  use Ecto.Schema
  import Ecto.Changeset

  schema "prompts" do
    field :title, :string
    field :content, :string
    field :variables, :map, default: %{}
    field :is_active, :boolean, default: true
    field :api_accessible, :boolean, default: false
    field :department_ids, {:array, :integer}, default: []
    field :role_ids, {:array, :integer}, default: []

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(prompt, attrs) do
    prompt
    |> cast(attrs, [:title, :content, :variables, :department_ids, :role_ids, :is_active, :api_accessible])
    |> validate_required([:title, :content])
  end

  @doc """
  Process prompt content with variables
  """
  def process_content(%__MODULE__{content: content, variables: variables}, user_vars \\ %{}) do
    all_vars = Map.merge(variables, user_vars)

    Enum.reduce(all_vars, content, fn {key, value}, acc ->
      String.replace(acc, "{#{key}}", to_string(value))
    end)
  end

  @doc """
  Extract variables from prompt content
  """
  def extract_variables(%__MODULE__{content: content}) do
    Regex.scan(~r/\{([^}]+)\}/, content)
    |> Enum.map(fn [_, var] -> String.to_atom(var) end)
    |> Enum.uniq()
  end
end
