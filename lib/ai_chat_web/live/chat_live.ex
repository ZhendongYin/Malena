defmodule AiChatWeb.ChatLive do
  use AiChatWeb, :live_view

  alias AiChat.{Chat, AiApis, AiClient, Prompts, KnowledgeBases}
  import AiChatWeb.Layouts

  on_mount AiChatWeb.LiveAuth

  @impl true
  def mount(_params, _session, socket) do
    # Current user is already set by on_mount callback
    current_user = socket.assigns.current_user
    conversations = Chat.list_user_conversations(current_user.id)

    # Get current AI API info
    current_ai_api = AiApis.get_ai_api_for_user(current_user)

    # If no conversations exist, create a new one
    socket =
      if Enum.empty?(conversations) do
        case Chat.create_conversation(%{"title" => "New Chat", "user_id" => current_user.id}) do
          {:ok, new_conversation} ->
            conversations = [new_conversation]
            socket
            |> assign(:conversations, conversations)
            |> assign(:current_conversation, new_conversation)
            |> assign(:messages, [])
            |> assign(:new_message, "")
            |> assign(:is_loading, false)
            |> assign(:is_streaming, false)
            |> assign(:streaming_content, "")
            |> assign(:streaming_think_content, "")
            |> assign(:final_think_content, "")
            |> assign(:show_think_content, true)
            |> assign(:current_ai_api, current_ai_api)
            |> assign(:current_page, "chat")
          {:error, _} ->
            socket
            |> assign(:conversations, conversations)
            |> assign(:current_conversation, nil)
            |> assign(:messages, [])
            |> assign(:new_message, "")
            |> assign(:is_loading, false)
            |> assign(:is_streaming, false)
            |> assign(:streaming_content, "")
            |> assign(:streaming_think_content, "")
            |> assign(:final_think_content, "")
            |> assign(:show_think_content, true)
            |> assign(:current_ai_api, current_ai_api)
            |> assign(:current_page, "chat")
        end
      else
        socket
        |> assign(:conversations, conversations)
        |> assign(:current_conversation, nil)
        |> assign(:messages, [])
        |> assign(:new_message, "")
        |> assign(:is_loading, false)
        |> assign(:current_ai_api, current_ai_api)
        |> assign(:current_page, "chat")
      end

    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => conversation_id}, _url, socket) do
    case Chat.get_conversation(conversation_id) do
      nil ->
        {:noreply,
         socket
         |> put_flash(:error, "Conversation not found")
         |> push_patch(to: ~p"/chat")}

      conversation ->
        if conversation.user_id == socket.assigns.current_user.id do
          messages = Chat.list_conversation_messages(conversation.id)

          {:noreply,
           socket
           |> assign(:current_conversation, conversation)
           |> assign(:messages, messages)
           |> assign(:is_streaming, false)
           |> assign(:streaming_content, "")
           |> assign(:streaming_think_content, "")
           |> assign(:final_think_content, "")
           |> assign(:show_think_content, true)}
        else
          {:noreply,
           socket
           |> put_flash(:error, "Access denied")
           |> push_patch(to: ~p"/chat")}
        end
    end
  end

  def handle_params(_params, _url, socket) do
    # If no conversation ID provided, select the first conversation
    conversations = socket.assigns.conversations

    if not Enum.empty?(conversations) and is_nil(socket.assigns.current_conversation) do
      first_conversation = List.first(conversations)
      messages = Chat.list_conversation_messages(first_conversation.id)

      {:noreply,
       socket
       |> assign(:current_conversation, first_conversation)
       |> assign(:messages, messages)
       |> assign(:is_streaming, false)
       |> assign(:streaming_content, "")
       |> assign(:streaming_think_content, "")
       |> assign(:final_think_content, "")
       |> assign(:show_think_content, true)}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_event("create_conversation", %{"conversation" => conversation_params}, socket) do
    user = socket.assigns.current_user

    case Chat.create_conversation(Map.put(conversation_params, "user_id", user.id)) do
      {:ok, conversation} ->
        conversations = Chat.list_user_conversations(user.id)

        {:noreply,
         socket
         |> assign(:conversations, conversations)
         |> put_flash(:info, "Conversation created successfully")
         |> push_patch(to: ~p"/chat/#{conversation.id}")}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Failed to create conversation")}
    end
  end

  # Toggle think content visibility
  @impl true
  def handle_event("toggle_think_content", _params, socket) do
    {:noreply, assign(socket, :show_think_content, !socket.assigns.show_think_content)}
  end

  @impl true
  def handle_event("update_message", %{"message" => message}, socket) do
    {:noreply, assign(socket, :new_message, message)}
  end

  def handle_event("update_message", %{"value" => message}, socket) do
    {:noreply, assign(socket, :new_message, message)}
  end

  @impl true
  def handle_event("send_message", %{"message" => message_params}, socket) do
    user = socket.assigns.current_user
    conversation = socket.assigns.current_conversation

    if conversation do
      # Create a temporary user message for immediate display
      temp_user_message = %{
        id: "temp_#{System.unique_integer([:positive])}",
        role: "user",
        content: message_params["content"],
        conversation_id: conversation.id,
        inserted_at: DateTime.utc_now()
      }

      # Show user message immediately
      messages = socket.assigns.messages ++ [temp_user_message]
      socket =
        socket
        |> assign(:messages, messages)
        |> assign(:new_message, "")
        |> assign(:is_loading, true)

      # Send async message to handle the rest
      send(self(), {:process_message, message_params, conversation, user, temp_user_message, messages})

      {:noreply, socket}
    else
      {:noreply, put_flash(socket, :error, "No conversation selected")}
    end
  end


  @impl true
  def handle_event("handle_enter", %{"key" => "Enter", "ctrlKey" => false}, socket) do
    # Only send if not loading and message is not empty
    if not socket.assigns.is_loading and String.trim(socket.assigns.new_message) != "" do
      handle_event("send_message", %{"message" => %{"content" => socket.assigns.new_message}}, socket)
    else
      {:noreply, socket}
    end
  end

  def handle_event("handle_enter", _params, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("delete_conversation", %{"id" => conversation_id}, socket) do
    case Chat.delete_conversation(conversation_id) do
      {:ok, _} ->
        conversations = Chat.list_user_conversations(socket.assigns.current_user.id)

        # Convert conversation_id to integer for comparison
        conversation_id_int = String.to_integer(conversation_id)

        # If we deleted the current conversation, create a new one
        socket =
          if socket.assigns.current_conversation && socket.assigns.current_conversation.id == conversation_id_int do
            # Create a new conversation
            user = socket.assigns.current_user
            conversation_params = %{
              "title" => "New Chat",
              "user_id" => user.id
            }

            case Chat.create_conversation(conversation_params) do
              {:ok, new_conversation} ->
                updated_conversations = Chat.list_user_conversations(user.id)
                socket
                |> assign(:conversations, updated_conversations)
                |> assign(:current_conversation, new_conversation)
                |> assign(:messages, [])
                |> assign(:is_streaming, false)
                |> assign(:streaming_content, "")
                |> assign(:streaming_think_content, "")
                |> assign(:final_think_content, "")
                |> assign(:show_think_content, true)
                |> push_patch(to: ~p"/chat/#{new_conversation.id}")
              {:error, _} ->
                socket
                |> assign(:conversations, conversations)
                |> assign(:current_conversation, nil)
                |> assign(:messages, [])
                |> assign(:is_streaming, false)
                |> assign(:streaming_content, "")
                |> assign(:streaming_think_content, "")
                |> assign(:final_think_content, "")
                |> assign(:show_think_content, true)
                |> push_patch(to: ~p"/chat")
            end
          else
            socket
            |> assign(:conversations, conversations)
            |> push_patch(to: ~p"/chat")
          end

        {:noreply,
         socket
         |> put_flash(:info, "Conversation deleted successfully")}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Failed to delete conversation")}
    end
  end

  @impl true
  def handle_event("clear_history", _params, socket) do
    case socket.assigns.current_conversation do
      nil -> {:noreply, socket}
      conversation ->
        Chat.delete_messages_for_conversation(conversation.id)
        {:noreply, assign(socket, :messages, [])}
    end
  end

  @impl true
  def handle_event("select_conversation", %{"id" => conversation_id}, socket) do
    {:noreply, push_patch(socket, to: ~p"/chat/#{conversation_id}")}
  end

  @impl true
  def handle_event("rename_conversation", %{"id" => _conversation_id}, socket) do
    # For now, just show a flash message. In a real app, you might want to show a modal or inline edit
    {:noreply, put_flash(socket, :info, "Rename functionality coming soon!")}
  end

  @impl true
  def handle_event("quick_start", _params, socket) do
    user = socket.assigns.current_user

    # Create a quick conversation
    conversation_params = %{
      "title" => "Quick Start Chat",
      "user_id" => user.id
    }

    case Chat.create_conversation(conversation_params) do
      {:ok, conversation} ->
        conversations = Chat.list_user_conversations(user.id)

        {:noreply,
         socket
         |> assign(:conversations, conversations)
         |> assign(:current_conversation, conversation)
         |> assign(:messages, [])
         |> put_flash(:info, "Quick start conversation created!")
         |> push_patch(to: ~p"/chat/#{conversation.id}")}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Failed to create quick start conversation")}
    end
  end

  @impl true
  def handle_info({:process_message, message_params, conversation, user, temp_user_message, messages}, socket) do
    # Auto-generate title if this is the first message
    socket =
      if length(messages) == 1 do
        # Generate title from first message
        title = generate_conversation_title(message_params["content"])
        case Chat.update_conversation(conversation, %{title: title}) do
          {:ok, updated_conversation} ->
            # Update conversations list
            conversations = Chat.list_user_conversations(user.id)
            socket
            |> assign(:conversations, conversations)
            |> assign(:current_conversation, updated_conversation)
          {:error, _} ->
            socket
        end
      else
        socket
      end

    # Now save the user message to database and get AI response
    user_message_params =
      message_params
      |> Map.put("role", "user")
      |> Map.put("conversation_id", conversation.id)

    case Chat.create_message(user_message_params) do
      {:ok, user_message} ->
        # Replace temp message with real message
        updated_messages =
          messages
          |> Enum.map(fn msg ->
            if msg.id == temp_user_message.id, do: user_message, else: msg
          end)

        # Get AI API and generate response
        case AiApis.get_ai_api_for_user(user) do
          nil ->
            {:noreply,
             socket
             |> assign(:messages, updated_messages)
             |> assign(:is_loading, false)
             |> put_flash(:error, "No AI API available. Please contact administrator.")}

          ai_api ->
            # Get conversation history for context
            conversation_history =
              updated_messages
              |> Enum.take(-10)  # Limit to last 10 messages for context
              |> Enum.map(fn msg -> %{role: msg.role, content: msg.content} end)

            # Get user's prompts and knowledge base chunks
            prompts = Prompts.get_prompts_for_user(user)
            knowledge_base_chunks = KnowledgeBases.search_knowledge_base_chunks(message_params["content"], user)

            # Try streaming first, fallback to regular response
            case AiClient.send_message_stream(ai_api, message_params["content"], conversation_history,
                   prompts: prompts, knowledge_base_chunks: knowledge_base_chunks, live_view_pid: self()) do
              {:ok, _stream_pid} ->
                # Start streaming response
                start_streaming_response(socket, conversation, updated_messages)

              {:error, _} ->
                # Fallback to regular non-streaming response
                case AiClient.send_message(ai_api, message_params["content"], conversation_history,
                       prompts: prompts, knowledge_base_chunks: knowledge_base_chunks) do
                  {:ok, ai_response} ->
                    ai_message_params = %{
                      "role" => "assistant",
                      "content" => ai_response,
                      "conversation_id" => conversation.id
                    }

                    case Chat.create_message(ai_message_params) do
                      {:ok, ai_message} ->
                        final_messages = updated_messages ++ [ai_message]

                        {:noreply,
                         socket
                         |> assign(:messages, final_messages)
                         |> assign(:is_loading, false)}

                      {:error, _changeset} ->
                        {:noreply,
                         socket
                         |> assign(:messages, updated_messages)
                         |> assign(:is_loading, false)
                         |> put_flash(:error, "Failed to save AI response")}
                    end

                  {:error, error} ->
                    {:noreply,
                     socket
                     |> assign(:messages, updated_messages)
                     |> assign(:is_loading, false)
                     |> put_flash(:error, "AI API error: #{error}")}
                end
            end
        end

      {:error, _changeset} ->
        # Remove temp message and show error
        messages_without_temp =
          messages
          |> Enum.reject(fn msg -> msg.id == temp_user_message.id end)

        {:noreply,
         socket
         |> assign(:messages, messages_without_temp)
         |> assign(:is_loading, false)
         |> put_flash(:error, "Failed to send message")}
    end
  end

  # Handle streaming think content
  @impl true
  def handle_info({:stream_think, think_content}, socket) do
    if socket.assigns.is_streaming do
      new_think_content = (socket.assigns.streaming_think_content || "") <> think_content

      {:noreply,
       socket
       |> assign(:streaming_think_content, new_think_content)
       |> assign(:is_loading, false)}
    else
      {:noreply, socket}
    end
  end

  # Handle streaming chunks
  @impl true
  def handle_info({:stream_chunk, chunk}, socket) do
    if socket.assigns.is_streaming do
      new_content = socket.assigns.streaming_content <> chunk

      # Update the temp AI message content
      updated_messages = Enum.map(socket.assigns.messages, fn msg ->
        if msg.id == socket.assigns.temp_ai_message_id do
          %{msg | content: new_content}
        else
          msg
        end
      end)

      {:noreply,
       socket
       |> assign(:messages, updated_messages)
       |> assign(:streaming_content, new_content)
       |> assign(:is_loading, false)}
    else
      {:noreply, socket}
    end
  end

  # Handle streaming think completion
  @impl true
  def handle_info({:stream_think_complete, think_content}, socket) do
    if socket.assigns.is_streaming do
      {:noreply,
       socket
       |> assign(:streaming_think_content, think_content)
       |> assign(:final_think_content, think_content)}
    else
      {:noreply, socket}
    end
  end

  # Handle streaming completion
  @impl true
  def handle_info({:stream_complete, final_content}, socket) do
    if socket.assigns.is_streaming do
      # Save the final message to database with think content in metadata
      metadata = %{}
      metadata = if socket.assigns.final_think_content != "" do
        Map.put(metadata, "think_content", socket.assigns.final_think_content)
      else
        metadata
      end

      ai_message_params = %{
        "role" => "assistant",
        "content" => final_content,
        "conversation_id" => socket.assigns.current_conversation.id,
        "metadata" => metadata
      }

      case Chat.create_message(ai_message_params) do
        {:ok, ai_message} ->
          # Replace temp message with real message
          final_messages = Enum.map(socket.assigns.messages, fn msg ->
            if msg.id == socket.assigns.temp_ai_message_id do
              ai_message
            else
              msg
            end
          end)

          {:noreply,
           socket
           |> assign(:messages, final_messages)
           |> assign(:is_streaming, false)
           |> assign(:streaming_content, "")
           |> assign(:streaming_think_content, "")
           |> assign(:final_think_content, "")
           |> assign(:temp_ai_message_id, nil)}

        {:error, _changeset} ->
          # Remove temp message and show error
          messages_without_temp = Enum.reject(socket.assigns.messages, fn msg ->
            msg.id == socket.assigns.temp_ai_message_id
          end)

          {:noreply,
           socket
           |> assign(:messages, messages_without_temp)
           |> assign(:is_streaming, false)
           |> assign(:streaming_content, "")
           |> assign(:streaming_think_content, "")
           |> assign(:final_think_content, "")
           |> assign(:temp_ai_message_id, nil)
           |> put_flash(:error, "Failed to save AI response")}
      end
    else
      {:noreply, socket}
    end
  end

  # Handle streaming errors
  @impl true
  def handle_info({:stream_error, error}, socket) do
    if socket.assigns.is_streaming do
      # Remove temp message and show error
      messages_without_temp = Enum.reject(socket.assigns.messages, fn msg ->
        msg.id == socket.assigns.temp_ai_message_id
      end)

      {:noreply,
       socket
       |> assign(:messages, messages_without_temp)
       |> assign(:is_streaming, false)
       |> assign(:streaming_content, "")
       |> assign(:streaming_think_content, "")
       |> assign(:final_think_content, "")
       |> assign(:temp_ai_message_id, nil)
       |> put_flash(:error, "Streaming error: #{error}")}
    else
      {:noreply, socket}
    end
  end

  # Handle HTTPoison async messages (ignore them as they're handled by the streaming process)
  @impl true
  def handle_info(%HTTPoison.AsyncStatus{}, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_info(%HTTPoison.AsyncHeaders{}, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_info(%HTTPoison.AsyncChunk{}, socket) do
    {:noreply, socket}
  end

  # Generate a conversation title from the first message
  defp generate_conversation_title(message) do
    # Simple title generation - take first 50 characters and clean up
    message
    |> String.trim()
    |> String.replace(~r/\s+/, " ")
    |> String.slice(0, 50)
    |> then(fn title ->
      if String.length(title) == 50 do
        title <> "..."
      else
        title
      end
    end)
  end

  # Start streaming response
  defp start_streaming_response(socket, conversation, updated_messages) do
    # Create a temporary AI message for streaming
    temp_ai_message = %{
      id: "temp_ai_#{System.unique_integer([:positive])}",
      role: "assistant",
      content: "",
      conversation_id: conversation.id,
      inserted_at: DateTime.utc_now(),
      updated_at: DateTime.utc_now()
    }

    # Add temp message to the messages list
    messages_with_temp = updated_messages ++ [temp_ai_message]

    {:noreply,
     socket
     |> assign(:messages, messages_with_temp)
     |> assign(:is_loading, false)
     |> assign(:is_streaming, true)
     |> assign(:streaming_content, "")
     |> assign(:streaming_think_content, "")
     |> assign(:final_think_content, "")
     |> assign(:show_think_content, true)
     |> assign(:temp_ai_message_id, temp_ai_message.id)}
  end

end
