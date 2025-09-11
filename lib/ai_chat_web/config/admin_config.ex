defmodule AiChatWeb.Config.AdminConfig do
  @moduledoc """
  Configuration module for admin interface settings.
  """

  @doc """
  Returns the list of available AI providers.
  """
  def ai_providers do
    [
      {"Select Provider", ""},
      {"OpenAI", "openai"},
      {"Anthropic", "anthropic"},
      {"Google", "google"},
      {"Ollama", "ollama"}
    ]
  end

  @doc """
  Returns the list of available permissions for roles.
  """
  def role_permissions do
    [
      %{key: "access_chat", label: "Access Chat"},
      %{key: "manage_users", label: "Manage Users"},
      %{key: "manage_departments", label: "Manage Departments"},
      %{key: "manage_roles", label: "Manage Roles"},
      %{key: "manage_prompts", label: "Manage Prompts"},
      %{key: "manage_knowledge_bases", label: "Manage Knowledge Bases"},
      %{key: "manage_ai_apis", label: "Manage AI APIs"},
      %{key: "view_analytics", label: "View Analytics"},
      %{key: "api_access", label: "API Access"}
    ]
  end

  @doc """
  Returns the list of available file types for knowledge bases.
  """
  def knowledge_base_file_types do
    [
      {"PDF", "pdf"},
      {"DOCX", "docx"},
      {"TXT", "txt"},
      {"Markdown", "md"}
    ]
  end

  @doc """
  Returns default form field configurations.
  """
  def default_form_config do
    %{
      text_fields: [:name, :title, :description, :api_key, :base_url, :model_name],
      email_fields: [:email],
      textarea_fields: [:content, :description],
      select_fields: [:provider, :department_id, :role_id, :preferred_ai_api_id, :file_type],
      checkbox_fields: [:is_active, :api_accessible, :is_processed],
      number_fields: [:rate_limit, :max_tokens, :temperature]
    }
  end

  @doc """
  Returns pagination settings.
  """
  def pagination_config do
    %{
      default_per_page: 20,
      max_per_page: 100,
      available_per_page: [10, 20, 50, 100]
    }
  end

  @doc """
  Returns table column configurations for different resources.
  """
  def table_columns do
    %{
      users: [
        %{key: :name, label: "Name", sortable: true},
        %{key: :email, label: "Email", sortable: true},
        %{key: :department, label: "Department", sortable: true},
        %{key: :role, label: "Role", sortable: true},
        %{key: :preferred_ai_api, label: "AI API", sortable: false},
        %{key: :is_active, label: "Status", sortable: true},
        %{key: :actions, label: "Actions", sortable: false}
      ],
      departments: [
        %{key: :name, label: "Name", sortable: true},
        %{key: :description, label: "Description", sortable: false},
        %{key: :is_active, label: "Status", sortable: true},
        %{key: :actions, label: "Actions", sortable: false}
      ],
      roles: [
        %{key: :name, label: "Name", sortable: true},
        %{key: :department, label: "Department", sortable: true},
        %{key: :permissions, label: "Permissions", sortable: false},
        %{key: :is_active, label: "Status", sortable: true},
        %{key: :actions, label: "Actions", sortable: false}
      ],
      prompts: [
        %{key: :title, label: "Title", sortable: true},
        %{key: :department, label: "Department", sortable: true},
        %{key: :role, label: "Role", sortable: true},
        %{key: :is_active, label: "Status", sortable: true},
        %{key: :actions, label: "Actions", sortable: false}
      ],
      knowledge_bases: [
        %{key: :name, label: "Name", sortable: true},
        %{key: :file_type, label: "Type", sortable: true},
        %{key: :department, label: "Department", sortable: true},
        %{key: :role, label: "Role", sortable: true},
        %{key: :is_active, label: "Status", sortable: true},
        %{key: :actions, label: "Actions", sortable: false}
      ],
      ai_apis: [
        %{key: :name, label: "Name", sortable: true},
        %{key: :provider, label: "Provider", sortable: true},
        %{key: :model_name, label: "Model", sortable: true},
        %{key: :is_active, label: "Status", sortable: true},
        %{key: :is_default, label: "Default", sortable: true},
        %{key: :actions, label: "Actions", sortable: false}
      ]
    }
  end
end
