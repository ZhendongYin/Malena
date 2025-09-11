defmodule AiChatWeb.Admin.RoleHTML do
  @moduledoc """
  This module contains pages rendered by RoleController.

  See the `role_html` directory for all templates available.
  """
  use AiChatWeb, :html

  embed_templates "role_html/*"
end
