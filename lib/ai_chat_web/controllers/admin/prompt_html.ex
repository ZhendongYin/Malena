defmodule AiChatWeb.Admin.PromptHTML do
  @moduledoc """
  This module contains pages rendered by PromptController.

  See the `prompt_html` directory for all templates available.
  """
  use AiChatWeb, :html

  embed_templates "prompt_html/*"
end
