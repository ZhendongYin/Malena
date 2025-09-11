defmodule AiChatWeb.Admin.KnowledgeBaseHTML do
  @moduledoc """
  This module contains pages rendered by KnowledgeBaseController.

  See the `knowledge_base_html` directory for all templates available.
  """
  use AiChatWeb, :html

  embed_templates "knowledge_base_html/*"
end
