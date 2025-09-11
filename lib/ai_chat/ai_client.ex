defmodule AiChat.AiClient do
  @moduledoc """
  AI Client module for communicating with various AI APIs.
  """


  @doc """
  Send a message to the AI API and get a response.
  """
  def send_message(ai_api, user_message, conversation_history \\ [], opts \\ []) do
    prompts = Keyword.get(opts, :prompts, [])
    knowledge_base_chunks = Keyword.get(opts, :knowledge_base_chunks, [])

    case ai_api.provider do
      "openai" -> call_openai_api(ai_api, user_message, conversation_history, prompts, knowledge_base_chunks)
      "claude" -> call_claude_api(ai_api, user_message, conversation_history, prompts, knowledge_base_chunks)
      "gemini" -> call_gemini_api(ai_api, user_message, conversation_history, prompts, knowledge_base_chunks)
      "ollama" -> call_ollama_api(ai_api, user_message, conversation_history, prompts, knowledge_base_chunks)
      _ -> {:error, "Unsupported AI provider: #{ai_api.provider}"}
    end
  end

  @doc """
  Send a message to the AI API and get a streaming response.
  Returns a function that yields chunks of the response.
  """
  def send_message_stream(ai_api, user_message, conversation_history \\ [], opts \\ []) do
    prompts = Keyword.get(opts, :prompts, [])
    knowledge_base_chunks = Keyword.get(opts, :knowledge_base_chunks, [])
    live_view_pid = Keyword.get(opts, :live_view_pid)

    case ai_api.provider do
      "ollama" -> call_ollama_api_stream(ai_api, user_message, conversation_history, prompts, knowledge_base_chunks, live_view_pid)
      _ -> {:error, "Streaming not supported for provider: #{ai_api.provider}"}
    end
  end

  # OpenAI API implementation
  defp call_openai_api(ai_api, user_message, conversation_history, prompts, knowledge_base_chunks) do
    messages = build_openai_messages(conversation_history, user_message, prompts, knowledge_base_chunks)

    request_body = %{
      model: ai_api.model_name,
      messages: messages,
      max_tokens: ai_api.max_tokens,
      temperature: ai_api.temperature
    }

    headers = [
      {"Authorization", "Bearer #{ai_api.api_key}"},
      {"Content-Type", "application/json"}
    ]

    url = "#{ai_api.base_url || "https://api.openai.com/v1"}/chat/completions"

    case HTTPoison.post(url, Jason.encode!(request_body), headers, [timeout: 60_000, recv_timeout: 60_000]) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        case Jason.decode(body) do
          {:ok, %{"choices" => [%{"message" => %{"content" => content}} | _]}} ->
            {:ok, content}
          {:ok, response} ->
            {:error, "Unexpected response format: #{inspect(response)}"}
          {:error, decode_error} ->
            {:error, "Failed to decode response: #{inspect(decode_error)}"}
        end
      {:ok, %HTTPoison.Response{status_code: status_code, body: body}} ->
        {:error, "API request failed with status #{status_code}: #{body}"}
      {:error, %HTTPoison.Error{reason: reason}} ->
        {:error, "HTTP request failed: #{inspect(reason)}"}
    end
  end

  # Claude API implementation
  defp call_claude_api(ai_api, user_message, conversation_history, prompts, knowledge_base_chunks) do
    # Build conversation context
    conversation_text = build_conversation_text(conversation_history, user_message, prompts, knowledge_base_chunks)

    request_body = %{
      model: ai_api.model_name,
      max_tokens: ai_api.max_tokens,
      temperature: ai_api.temperature,
      messages: [
        %{
          role: "user",
          content: conversation_text
        }
      ]
    }

    headers = [
      {"x-api-key", ai_api.api_key},
      {"Content-Type", "application/json"},
      {"anthropic-version", "2023-06-01"}
    ]

    url = "#{ai_api.base_url || "https://api.anthropic.com/v1"}/messages"

    case HTTPoison.post(url, Jason.encode!(request_body), headers, [timeout: 60_000, recv_timeout: 60_000]) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        case Jason.decode(body) do
          {:ok, %{"content" => [%{"text" => content} | _]}} ->
            {:ok, content}
          {:ok, response} ->
            {:error, "Unexpected response format: #{inspect(response)}"}
          {:error, decode_error} ->
            {:error, "Failed to decode response: #{inspect(decode_error)}"}
        end
      {:ok, %HTTPoison.Response{status_code: status_code, body: body}} ->
        {:error, "API request failed with status #{status_code}: #{body}"}
      {:error, %HTTPoison.Error{reason: reason}} ->
        {:error, "HTTP request failed: #{inspect(reason)}"}
    end
  end

  # Gemini API implementation
  defp call_gemini_api(ai_api, user_message, conversation_history, prompts, knowledge_base_chunks) do
    # Build conversation context
    conversation_text = build_conversation_text(conversation_history, user_message, prompts, knowledge_base_chunks)

    request_body = %{
      contents: [
        %{
          parts: [
            %{
              text: conversation_text
            }
          ]
        }
      ],
      generationConfig: %{
        maxOutputTokens: ai_api.max_tokens,
        temperature: ai_api.temperature
      }
    }

    headers = [
      {"Content-Type", "application/json"}
    ]

    url = "#{ai_api.base_url || "https://generativelanguage.googleapis.com/v1"}/models/#{ai_api.model_name}:generateContent?key=#{ai_api.api_key}"

    case HTTPoison.post(url, Jason.encode!(request_body), headers, [timeout: 60_000, recv_timeout: 60_000]) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        case Jason.decode(body) do
          {:ok, %{"candidates" => [%{"content" => %{"parts" => [%{"text" => content} | _]}} | _]}} ->
            {:ok, content}
          {:ok, response} ->
            {:error, "Unexpected response format: #{inspect(response)}"}
          {:error, decode_error} ->
            {:error, "Failed to decode response: #{inspect(decode_error)}"}
        end
      {:ok, %HTTPoison.Response{status_code: status_code, body: body}} ->
        {:error, "API request failed with status #{status_code}: #{body}"}
      {:error, %HTTPoison.Error{reason: reason}} ->
        {:error, "HTTP request failed: #{inspect(reason)}"}
    end
  end

  # Ollama API implementation
  defp call_ollama_api(ai_api, user_message, conversation_history, prompts, knowledge_base_chunks) do
    # Build messages array for chat API
    messages = build_ollama_messages(conversation_history, user_message, prompts, knowledge_base_chunks)

    request_body = %{
      model: ai_api.model_name,
      messages: messages,
      stream: false,
      options: %{
        temperature: ai_api.temperature,
        num_predict: ai_api.max_tokens
      }
    }

    headers = [
      {"Content-Type", "application/json"}
    ]

    url = "#{ai_api.base_url || "http://localhost:11434"}/api/chat"

    case HTTPoison.post(url, Jason.encode!(request_body), headers, [timeout: 60_000, recv_timeout: 60_000]) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        case Jason.decode(body) do
          {:ok, %{"message" => %{"content" => content}}} ->
            {:ok, content}
          {:ok, response} ->
            {:error, "Unexpected response format: #{inspect(response)}"}
          {:error, decode_error} ->
            {:error, "Failed to decode response: #{inspect(decode_error)}"}
        end
      {:ok, %HTTPoison.Response{status_code: status_code, body: body}} ->
        {:error, "API request failed with status #{status_code}: #{body}"}
      {:error, %HTTPoison.Error{reason: reason}} ->
        {:error, "HTTP request failed: #{inspect(reason)}"}
    end
  end

  # Ollama API streaming implementation
  defp call_ollama_api_stream(ai_api, user_message, conversation_history, prompts, knowledge_base_chunks, live_view_pid) do
    # Build messages array for chat API
    messages = build_ollama_messages(conversation_history, user_message, prompts, knowledge_base_chunks)

    request_body = %{
      model: ai_api.model_name,
      messages: messages,
      stream: true,
      options: %{
        temperature: ai_api.temperature,
        num_predict: ai_api.max_tokens
      }
    }

    headers = [
      {"Content-Type", "application/json"}
    ]

    url = "#{ai_api.base_url || "http://localhost:11434"}/api/chat"

    # Start a process to handle the stream first
    stream_pid = spawn(fn -> process_ollama_stream(nil, "", live_view_pid) end)

    # Use HTTPoison with streaming, send messages to the stream process
    case HTTPoison.post(url, Jason.encode!(request_body), headers, [timeout: 60_000, recv_timeout: 60_000, stream_to: stream_pid]) do
      {:ok, %HTTPoison.AsyncResponse{id: id}} ->
        # Send the response ID to the stream process
        send(stream_pid, {:set_response_id, id})
        {:ok, stream_pid}
      {:error, %HTTPoison.Error{reason: reason}} ->
        # Kill the stream process if request failed
        Process.exit(stream_pid, :kill)
        {:error, "HTTP request failed: #{inspect(reason)}"}
    end
  end

  # Parse complete content to separate think tags from actual response
  defp parse_complete_content(content) do
    # Look for <think> tags in the complete content (both regular and HTML encoded)
    case Regex.run(~r/<think>(.*?)<\/think>/s, content) do
      [_, think_content] ->
        # Extract think content and remove it from the response
        response_content = String.replace(content, ~r/<think>.*?<\/think>/s, "", global: true)
        # Also remove any remaining <think> or </think> tags
        response_content = String.replace(response_content, ~r/<think>|<\/think>/, "", global: true)
        {String.trim(think_content), String.trim(response_content)}
      nil ->
        # Try HTML encoded version
        case Regex.run(~r/\\u003cthink\\u003e(.*?)\\u003c\/think\\u003e/s, content) do
          [_, think_content] ->
            # Extract think content and remove it from the response
            response_content = String.replace(content, ~r/\\u003cthink\\u003e.*?\\u003c\/think\\u003e/s, "", global: true)
            # Also remove any remaining encoded think tags
            response_content = String.replace(response_content, ~r/\\u003cthink\\u003e|\\u003c\/think\\u003e/, "", global: true)
            {String.trim(think_content), String.trim(response_content)}
          nil ->
            # No think tags found, but still clean up any stray tags
            cleaned_content = String.replace(content, ~r/<think>|<\/think>|\\u003cthink\\u003e|\\u003c\/think\\u003e/, "", global: true)
            {"", cleaned_content}
        end
    end
  end

  # Process streaming response from Ollama
  defp process_ollama_stream(id, acc, live_view_pid) do
    receive do
      {:set_response_id, response_id} ->
        # Update the response ID and continue processing
        process_ollama_stream(response_id, acc, live_view_pid)

      %HTTPoison.AsyncChunk{id: ^id, chunk: chunk} ->
        # Parse each chunk as JSON
        case Jason.decode(chunk) do
          {:ok, %{"message" => %{"content" => content}}} ->
            # Only send non-think content to LiveView for streaming display
            # Skip content that contains think tags to avoid duplication
            if not String.contains?(content, "<think>") and not String.contains?(content, "</think>") and
               not String.contains?(content, "\\u003cthink\\u003e") and not String.contains?(content, "\\u003c/think\\u003e") do
              if live_view_pid do
                send(live_view_pid, {:stream_chunk, content})
              end
            end

            # Continue processing
            process_ollama_stream(id, acc <> content, live_view_pid)
          {:ok, %{"done" => true}} ->
            # Stream is complete, parse and send final content to LiveView
            {think_content, response_content} = parse_complete_content(acc)

            if live_view_pid do
              if think_content != "" do
                send(live_view_pid, {:stream_think_complete, think_content})
              end
              send(live_view_pid, {:stream_complete, response_content})
            end
          {:ok, _} ->
            # Continue processing
            process_ollama_stream(id, acc, live_view_pid)
          {:error, _} ->
            # Skip invalid JSON chunks
            process_ollama_stream(id, acc, live_view_pid)
        end
      %HTTPoison.AsyncEnd{id: ^id} ->
        # Stream ended, parse and send final content to LiveView
        {think_content, response_content} = parse_complete_content(acc)

        if live_view_pid do
          if think_content != "" do
            send(live_view_pid, {:stream_think_complete, think_content})
          end
          send(live_view_pid, {:stream_complete, response_content})
        end
      %HTTPoison.AsyncStatus{id: ^id, code: code} when code != 200 ->
        # Send error to LiveView
        if live_view_pid do
          send(live_view_pid, {:stream_error, "HTTP error: #{code}"})
        end
    after
      30_000 ->
        # Send timeout error to LiveView
        if live_view_pid do
          send(live_view_pid, {:stream_error, "Stream timeout"})
        end
    end
  end

  # Helper function to build OpenAI messages format
  defp build_openai_messages(conversation_history, user_message, prompts, knowledge_base_chunks) do
    # Build system message with prompts and knowledge base context
    system_content = build_system_content(prompts, knowledge_base_chunks)

    # Convert conversation history to OpenAI format
    history_messages = Enum.map(conversation_history, fn message ->
      %{
        role: message.role,
        content: message.content
      }
    end)

    # Add system message if we have prompts or knowledge base content
    messages = if system_content != "" do
      [%{role: "system", content: system_content}] ++ history_messages
    else
      history_messages
    end

    # Add the current user message
    messages ++ [%{role: "user", content: user_message}]
  end

  # Helper function to build Ollama messages format
  defp build_ollama_messages(conversation_history, user_message, prompts, knowledge_base_chunks) do
    # Build system message with prompts and knowledge base context
    system_content = build_system_content(prompts, knowledge_base_chunks)

    # Convert conversation history to Ollama format
    history_messages = Enum.map(conversation_history, fn message ->
      %{
        role: message.role,
        content: message.content
      }
    end)

    # Add system message if we have prompts or knowledge base content
    messages = if system_content != "" do
      [%{role: "system", content: system_content}] ++ history_messages
    else
      history_messages
    end

    # Add the current user message
    messages ++ [%{role: "user", content: user_message}]
  end

  # Helper function to build conversation text for APIs that don't support message arrays
  defp build_conversation_text(conversation_history, user_message, prompts, knowledge_base_chunks) do
    # Build system content
    system_content = build_system_content(prompts, knowledge_base_chunks)

    # Build a simple conversation format
    history_text = Enum.map(conversation_history, fn message ->
      "#{String.capitalize(message.role)}: #{message.content}"
    end)
    |> Enum.join("\n")

    # Combine system content, history, and current message
    parts = []
    parts = if system_content != "" do
      parts ++ ["System Instructions: #{system_content}"]
    else
      parts
    end

    parts = if history_text != "" do
      parts ++ [history_text]
    else
      parts
    end

    parts = parts ++ ["User: #{user_message}"]

    Enum.join(parts, "\n\n")
  end

  # Helper function to build system content from prompts and knowledge base chunks
  defp build_system_content(prompts, knowledge_base_chunks) do
    parts = []

    # Add prompts
    parts = if length(prompts) > 0 do
      prompt_text = prompts
      |> Enum.map(& &1.content)
      |> Enum.join("\n\n")
      parts ++ ["Instructions: #{prompt_text}"]
    else
      parts
    end

    # Add knowledge base context
    parts = if length(knowledge_base_chunks) > 0 do
      kb_text = knowledge_base_chunks
      |> Enum.map(fn chunk ->
        kb_name = Map.get(chunk, :knowledge_base_name, "Unknown")
        content = Map.get(chunk, :content, "")
        "From #{kb_name}: #{content}"
      end)
      |> Enum.join("\n\n")
      parts ++ ["Relevant Information: #{kb_text}"]
    else
      parts
    end

    Enum.join(parts, "\n\n")
  end
end
