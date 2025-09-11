defmodule AiChatWeb.Admin.AiApiHTML do
  @moduledoc """
  This module contains pages rendered by AiApiController.

  See the `ai_api_html` directory for all templates available.
  """
  use AiChatWeb, :html

  embed_templates "ai_api_html/*"
end
