defmodule AiChatWeb.LiveAuth do
  @moduledoc """
  Authentication helpers for LiveView
  """

  import Phoenix.Component
  import Phoenix.LiveView

  alias AiChat.Accounts.Guardian
  alias AiChat.Repo

  def on_mount(:default, _params, session, socket) do
    socket = assign_current_user(socket, session)

    if socket.assigns.current_user do
      {:cont, socket}
    else
      {:halt, redirect(socket, to: "/login")}
    end
  end

  def on_mount(:optional, _params, session, socket) do
    socket = assign_current_user(socket, session)
    {:cont, socket}
  end

  defp assign_current_user(socket, session) do
    # Try various possible Guardian session keys
    token = session["guardian_default_token"] ||
            session["_guardian_default_token"] ||
            session[:guardian_default_token] ||
            session[:_guardian_default_token]

    case token do
      nil ->
        assign(socket, :current_user, nil)
      token ->
        try do
          case Guardian.decode_and_verify(token) do
            {:ok, claims} ->
              case Guardian.resource_from_claims(claims) do
                {:ok, user} ->
                  user = Repo.preload(user, [:department, :role])
                  assign(socket, :current_user, user)
                {:error, _reason} ->
                  assign(socket, :current_user, nil)
              end
            {:error, _reason} ->
              assign(socket, :current_user, nil)
          end
        rescue
          _error ->
            assign(socket, :current_user, nil)
        end
    end
  end
end
