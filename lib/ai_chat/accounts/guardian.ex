defmodule AiChat.Accounts.Guardian do
  use Guardian, otp_app: :ai_chat

  alias AiChat.Accounts

  def subject_for_token(user, _claims) do
    {:ok, to_string(user.id)}
  end

  def resource_from_claims(claims) do
    user_id = claims["sub"]
    user = Accounts.get_user!(user_id)
    {:ok, user}
  rescue
    Ecto.NoResultsError -> {:error, :resource_not_found}
  end
end
