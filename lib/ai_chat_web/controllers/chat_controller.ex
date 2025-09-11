defmodule AiChatWeb.ChatController do
  use AiChatWeb, :controller

  alias AiChat.Chat

  def index(conn, _params) do
    user = conn.assigns.current_user
    conversations = Chat.list_user_conversations(user.id)

    render(conn, "index.html", conversations: conversations)
  end

  def show(conn, %{"id" => id}) do
    user = conn.assigns.current_user

    case Chat.get_conversation(id) do
      nil ->
        conn
        |> put_flash(:error, "Conversation not found")
        |> redirect(to: ~p"/chat")

      conversation ->
        if conversation.user_id == user.id do
          messages = Chat.list_conversation_messages(conversation.id)
          render(conn, "show.html", conversation: conversation, messages: messages)
        else
          conn
          |> put_flash(:error, "Access denied")
          |> redirect(to: ~p"/chat")
        end
    end
  end

  def new(conn, _params) do
    changeset = Chat.change_conversation(%Chat.Conversation{})

    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"conversation" => conversation_params}) do
    user = conn.assigns.current_user

    # Generate default title if not provided
    conversation_params =
      if conversation_params["title"] == "" or conversation_params["title"] == nil do
        timestamp = DateTime.utc_now() |> DateTime.to_date() |> Date.to_string()
        Map.put(conversation_params, "title", "Conversation on #{timestamp}")
      else
        conversation_params
      end

    case Chat.create_conversation(Map.put(conversation_params, "user_id", user.id)) do
      {:ok, conversation} ->
        conn
        |> put_flash(:info, "Conversation created successfully")
        |> redirect(to: ~p"/chat/#{conversation.id}")

      {:error, changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  def create_message(conn, %{"id" => conversation_id, "message" => message_params}) do
    user = conn.assigns.current_user

    case Chat.get_conversation(conversation_id) do
      nil ->
        conn
        |> put_flash(:error, "Conversation not found")
        |> redirect(to: ~p"/chat")

      conversation ->
        if conversation.user_id == user.id do
          # Create user message
          user_message_params = Map.put(message_params, "role", "user")
          |> Map.put("conversation_id", conversation_id)

          case Chat.create_message(user_message_params) do
            {:ok, _user_message} ->
              # Get AI API for the user
              case AiChat.AiApis.get_ai_api_for_user(user) do
                nil ->
                  conn
                  |> put_flash(:error, "No AI API available. Please contact administrator.")
                  |> redirect(to: ~p"/chat/#{conversation_id}")

                ai_api ->
                  # Get conversation history for context
                  conversation_history = Chat.list_conversation_messages(conversation_id)
                  |> Enum.take(-10)  # Limit to last 10 messages for context

                  # Call AI API to generate response
                  case AiChat.AiClient.send_message(ai_api, message_params["content"], conversation_history) do
                    {:ok, ai_response} ->
                      ai_message_params = %{
                        "role" => "assistant",
                        "content" => ai_response,
                        "conversation_id" => conversation_id
                      }

                      case Chat.create_message(ai_message_params) do
                        {:ok, _ai_message} ->
                          conn
                          |> redirect(to: ~p"/chat/#{conversation_id}")

                        {:error, _changeset} ->
                          conn
                          |> put_flash(:error, "Failed to create AI response")
                          |> redirect(to: ~p"/chat/#{conversation_id}")
                      end

                    {:error, error_message} ->
                      # Create error response message with helpful information
                      error_content = case ai_api.provider do
                        "ollama" ->
                          "Sorry, I'm currently unavailable. This might be because:

                          1. Ollama service is not running on your local machine
                          2. The model '#{ai_api.model_name}' is not installed
                          3. Ollama is not accessible at #{ai_api.base_url}

                          Please check your Ollama installation and try again. Error: #{error_message}"
                        _ ->
                          "Sorry, I encountered an error: #{error_message}. Please try again or contact support."
                      end

                      error_response_params = %{
                        "role" => "assistant",
                        "content" => error_content,
                        "conversation_id" => conversation_id
                      }

                      case Chat.create_message(error_response_params) do
                        {:ok, _ai_message} ->
                          conn
                          |> put_flash(:error, "AI API error: #{error_message}")
                          |> redirect(to: ~p"/chat/#{conversation_id}")

                        {:error, _changeset} ->
                          conn
                          |> put_flash(:error, "Failed to create error response")
                          |> redirect(to: ~p"/chat/#{conversation_id}")
                      end
                  end
              end

            {:error, _changeset} ->
              conn
              |> put_flash(:error, "Failed to send message")
              |> redirect(to: ~p"/chat/#{conversation_id}")
          end
        else
          conn
          |> put_flash(:error, "Access denied")
          |> redirect(to: ~p"/chat")
        end
    end
  end
end
