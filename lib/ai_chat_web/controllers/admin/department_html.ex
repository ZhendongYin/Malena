defmodule AiChatWeb.Admin.DepartmentHTML do
  @moduledoc """
  This module contains pages rendered by DepartmentController.

  See the `department_html` directory for all templates available.
  """
  use AiChatWeb, :html

  embed_templates "department_html/*"
end
