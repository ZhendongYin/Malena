defmodule AiChat.Accounts.Permissions do
  @moduledoc """
  Permission system for the AI Chat platform.
  """

  alias AiChat.Accounts.User
  alias AiChat.Organizations.Role

  @doc """
  Check if user has a specific permission.
  """
  def has_permission?(%User{role: %Role{} = role}, permission) do
    Role.has_permission?(role, permission)
  end

  def has_permission?(%User{role_id: role_id}, permission) when not is_nil(role_id) do
    case AiChat.Repo.get(AiChat.Organizations.Role, role_id) do
      nil -> false
      role -> Role.has_permission?(role, permission)
    end
  end

  def has_permission?(%User{role: nil}, _permission), do: false
  def has_permission?(%User{}, _permission), do: false
  def has_permission?(nil, _permission), do: false

  @doc """
  Check if user has a specific API permission.
  """
  def has_api_permission?(%User{role: %Role{} = role}, permission) do
    Role.has_api_permission?(role, permission)
  end

  def has_api_permission?(%User{role_id: role_id}, permission) when not is_nil(role_id) do
    case AiChat.Repo.get(AiChat.Organizations.Role, role_id) do
      nil -> false
      role -> Role.has_api_permission?(role, permission)
    end
  end

  def has_api_permission?(%User{role: nil}, _permission), do: false
  def has_api_permission?(%User{}, _permission), do: false
  def has_api_permission?(nil, _permission), do: false

  @doc """
  Check if user is a super admin.
  """
  def is_super_admin?(%User{role: %Role{permissions: permissions}}) do
    get_in(permissions, ["super_admin"]) == true
  end

  def is_super_admin?(_), do: false

  @doc """
  Check if user is a department admin.
  """
  def is_department_admin?(%User{role: %Role{permissions: permissions}}) do
    get_in(permissions, ["department_admin"]) == true
  end

  def is_department_admin?(_), do: false

  @doc """
  Check if user can access a specific department.
  """
  def can_access_department?(%User{department_id: user_dept_id}, department_id) do
    user_dept_id == department_id
  end

  @doc """
  Check if user can manage users in their department.
  """
  def can_manage_users?(%User{} = user) do
    has_permission?(user, "super_admin") or has_permission?(user, "department_admin") or has_permission?(user, "manage_users")
  end

  @doc """
  Check if user can manage prompts.
  """
  def can_manage_prompts?(%User{} = user) do
    has_permission?(user, "super_admin") or has_permission?(user, "department_admin") or has_permission?(user, "manage_prompts")
  end

  @doc """
  Check if user can manage knowledge bases.
  """
  def can_manage_knowledge_bases?(%User{} = user) do
    has_permission?(user, "super_admin") or has_permission?(user, "department_admin") or has_permission?(user, "manage_knowledge_bases")
  end

  @doc """
  Check if user can manage AI APIs.
  """
  def can_manage_ai_apis?(%User{} = user) do
    has_permission?(user, "super_admin") or has_permission?(user, "manage_ai_apis")
  end

  @doc """
  Check if user can access chat.
  """
  def can_access_chat?(%User{is_active: true}), do: true
  def can_access_chat?(_), do: false

  @doc """
  Check if user has admin access (has any management permissions).
  """
  def has_admin_access?(%User{} = user) do
    has_permission?(user, "manage_roles") or
    has_permission?(user, "manage_departments") or
    has_permission?(user, "manage_prompts") or
    has_permission?(user, "manage_knowledge_bases") or
    has_permission?(user, "manage_ai_apis") or
    has_permission?(user, "view_analytics")
  end

  def has_admin_access?(_), do: false

  @doc """
  Get user's accessible departments.
  """
  def get_accessible_departments(%User{} = user) do
    if has_permission?(user, "super_admin") do
      # Super admin can access all departments
      AiChat.Organizations.list_departments()
    else
      # Regular users can only access their own department
      if user.department_id do
        [AiChat.Organizations.get_department!(user.department_id)]
      else
        []
      end
    end
  end
end
