defmodule AiChatWeb.Plugs.ApiAuth do
  @moduledoc """
  API authentication plug for API requests.
  """

  import Plug.Conn
  import Phoenix.Controller
  alias AiChat.ApiKeys
  alias AiChat.Accounts

  def init(opts), do: opts

  def call(conn, _opts) do
    case get_api_key_from_header(conn) do
      nil ->
        conn
        |> put_status(:unauthorized)
        |> json(%{error: "API key required"})
        |> halt()

      api_key ->
        case ApiKeys.authenticate_api_key(api_key) do
          {:ok, api_key_record} ->
            user = Accounts.get_user!(api_key_record.user_id)
            conn
            |> assign(:current_api_key, api_key_record)
            |> assign(:current_user, user)

          {:error, :invalid_key} ->
            conn
            |> put_status(:unauthorized)
            |> json(%{error: "Invalid API key"})
            |> halt()

          {:error, :expired} ->
            conn
            |> put_status(:unauthorized)
            |> json(%{error: "API key expired"})
            |> halt()

          {:error, :suspended} ->
            conn
            |> put_status(:forbidden)
            |> json(%{error: "API key suspended"})
            |> halt()
        end
    end
  end

  defp get_api_key_from_header(conn) do
    case get_req_header(conn, "authorization") do
      ["Bearer " <> api_key] -> api_key
      _ -> nil
    end
  end
end
