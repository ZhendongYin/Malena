defmodule AiChatWeb.AuthPipeline do
  use Guardian.Plug.Pipeline, otp_app: :ai_chat,
    module: AiChat.Accounts.Guardian,
    error_handler: AiChatWeb.AuthErrorHandler

  plug Guardian.Plug.VerifySession, key: :default
  plug Guardian.Plug.LoadResource, allow_blank: true
end


