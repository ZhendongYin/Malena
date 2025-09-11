defmodule AiChatWeb.Plugs.Authorization do
  @moduledoc """
  Authorization plug for checking user permissions.
  """

  import Plug.Conn
  import Phoenix.Controller
  alias AiChat.Accounts.Permissions

  def init(required_permission), do: required_permission

  def call(conn, required_permission) do
    user = conn.assigns[:current_user]

    if user && has_permission?(user, required_permission) do
      conn
    else
      conn
      |> put_flash(:error, "You don't have permission to access this page.")
      |> redirect(to: "/")
      |> halt()
    end
  end

  defp has_permission?(user, permission) when is_atom(permission) do
    case permission do
      :super_admin -> Permissions.is_super_admin?(user)
      :department_admin -> Permissions.is_department_admin?(user)
      :manage_users -> Permissions.can_manage_users?(user)
      :manage_prompts -> Permissions.can_manage_prompts?(user)
      :manage_knowledge_bases -> Permissions.can_manage_knowledge_bases?(user)
      :manage_ai_apis -> Permissions.can_manage_ai_apis?(user)
      :access_chat -> Permissions.can_access_chat?(user)
      _ -> Permissions.has_permission?(user, permission)
    end
  end

  defp has_permission?(user, permission) when is_binary(permission) do
    Permissions.has_permission?(user, permission)
  end
end
