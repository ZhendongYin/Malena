defmodule AiChatWeb.FormComponents do
  @moduledoc """
  Reusable form components for consistent styling.
  """
  use Phoenix.Component

  @doc """
  Renders a standard form field with label and error handling.
  """
  attr :form, :any, required: true
  attr :field, :atom, required: true
  attr :label, :string, required: true
  attr :type, :string, default: "text"
  attr :placeholder, :string, default: ""
  attr :required, :boolean, default: false
  attr :options, :list, default: []
  attr :multiple, :boolean, default: false

  def form_field(assigns) do
    field_name = "#{assigns.form.name}[#{assigns.field}]"
    field_id = "#{assigns.form.name}_#{assigns.field}"
    current_value = get_in(assigns.form.changes, [assigns.field]) || Map.get(assigns.form.data, assigns.field) || ""
    has_error = assigns.form.errors[assigns.field] != nil

    assigns = assign(assigns, :field_name, field_name)
    assigns = assign(assigns, :field_id, field_id)
    assigns = assign(assigns, :current_value, current_value)
    assigns = assign(assigns, :has_error, has_error)

    ~H"""
    <div class="form-control">
      <label for={@field_id} class="block text-sm font-medium text-base-content">
        <%= @label %>
        <%= if @required do %>
          <span class="text-error">*</span>
        <% end %>
      </label>

      <div class="mt-1">
        <%= case @type do %>
          <% "select" -> %>
            <select
              name={@field_name}
              id={@field_id}
              class="input input-bordered w-full bg-base-100 text-base-content"
            >
              <option value="">Select <%= @label %></option>
              <option :for={option <- @options} value={elem(option, 1)} selected={@current_value == elem(option, 1)}>
                <%= elem(option, 0) %>
              </option>
            </select>
          <% "textarea" -> %>
            <textarea
              name={@field_name}
              id={@field_id}
              placeholder={@placeholder}
              class="textarea textarea-bordered w-full bg-base-100 text-base-content placeholder-base-content/50"
              rows="4"
            >{@current_value}</textarea>
          <% "checkbox" -> %>
            <input
              type="checkbox"
              name={@field_name}
              id={@field_id}
              value="true"
              checked={@current_value == true}
              class="checkbox checkbox-primary"
            />
          <% _ -> %>
            <input
              type={@type}
              name={@field_name}
              id={@field_id}
              value={@current_value}
              placeholder={@placeholder}
              class="input input-bordered w-full bg-base-100 text-base-content placeholder-base-content/50"
            />
        <% end %>
      </div>

      <p :if={@has_error} class="mt-2 text-sm text-error">
        <%= elem(assigns.form.errors[assigns.field], 0) %>
      </p>
    </div>
    """
  end

  @doc """
  Renders a department select field with "All" option.
  """
  attr :form, :any, required: true
  attr :field, :atom, required: true
  attr :departments, :list, required: true
  attr :label, :string, default: "Department"

  def department_select(assigns) do
    options = [
      {"All Departments", ""}
      | Enum.map(assigns.departments, &{&1.name, &1.id})
    ]

    assigns = assign(assigns, :options, options)

    ~H"""
    <.form_field
      form={@form}
      field={@field}
      label={@label}
      type="select"
      options={@options}
    />
    """
  end

  @doc """
  Renders a role select field with "All" option.
  """
  attr :form, :any, required: true
  attr :field, :atom, required: true
  attr :roles, :list, required: true
  attr :label, :string, default: "Role"

  def role_select(assigns) do
    options = [
      {"All Roles", ""}
      | Enum.map(assigns.roles, &{&1.name, &1.id})
    ]

    assigns = assign(assigns, :options, options)

    ~H"""
    <.form_field
      form={@form}
      field={@field}
      label={@label}
      type="select"
      options={@options}
    />
    """
  end

  @doc """
  Renders an AI API select field with "Default" option.
  """
  attr :form, :any, required: true
  attr :field, :atom, required: true
  attr :ai_apis, :list, required: true
  attr :label, :string, default: "Preferred AI API"

  def ai_api_select(assigns) do
    options = [
      {"Use Default", ""}
      | Enum.map(assigns.ai_apis, &{&1.name, &1.id})
    ]

    assigns = assign(assigns, :options, options)

    ~H"""
    <.form_field
      form={@form}
      field={@field}
      label={@label}
      type="select"
      options={@options}
    />
    """
  end

  @doc """
  Renders a provider select field for AI APIs.
  """
  attr :form, :any, required: true
  attr :field, :atom, required: true
  attr :label, :string, default: "Provider"

  def provider_select(assigns) do
    options = [
      {"Select Provider", ""},
      {"OpenAI", "openai"},
      {"Anthropic", "anthropic"},
      {"Google", "google"},
      {"Ollama", "ollama"}
    ]

    assigns = assign(assigns, :options, options)

    ~H"""
    <.form_field
      form={@form}
      field={@field}
      label={@label}
      type="select"
      options={@options}
      required={true}
    />
    """
  end

  @doc """
  Renders a permissions checkbox group for roles.
  """
  attr :form, :any, required: true
  attr :field, :atom, required: true
  attr :permissions, :list, required: true

  def permissions_checkbox_group(assigns) do
    ~H"""
    <div class="form-control">
      <label class="label">
        <span class="label-text text-base-content">Permissions</span>
      </label>

      <div class="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-3">
        <%= for permission <- @permissions do %>
          <div class="form-control">
            <label class="label cursor-pointer">
              <span class="label-text text-base-content"><%= permission.label %></span>
              <input
                type="checkbox"
                name={"#{assigns.form.name}[#{assigns.field}][#{permission.key}]"}
                id={"#{assigns.form.name}_#{assigns.field}_#{permission.key}"}
                value="true"
                class="checkbox checkbox-primary"
                checked={get_in(assigns.form.changes, [assigns.field]) |> then(fn perms -> if perms, do: Map.get(perms, permission.key), else: nil end) || assigns.form.data[assigns.field][permission.key]}
              />
            </label>
          </div>
        <% end %>
      </div>

      <p :if={assigns.form.errors[assigns.field]} class="mt-2 text-sm text-error">
        <%= elem(assigns.form.errors[assigns.field], 0) %>
      </p>
    </div>
    """
  end
end
