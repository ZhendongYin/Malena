# Script to add qwen3:1.7b model to AI APIs
# Run with: mix run add_qwen_model.exs

# Add qwen3:1.7b model
attrs = %{
  "name" => "Qwen3 1.7B",
  "provider" => "ollama",
  "api_key" => nil,
  "base_url" => "http://localhost:11434",
  "model_name" => "qwen3:1.7b",
  "is_active" => true,
  "is_default" => false,
  "rate_limit" => 100,
  "max_tokens" => 4000,
  "temperature" => 0.7,
  "config" => %{},
  "department_id" => nil,
  "role_id" => nil
}

case AiChat.AiApis.create_ai_api(attrs) do
  {:ok, ai_api} ->
    IO.puts("✅ Successfully added qwen3:1.7b model!")
    IO.puts("   ID: #{ai_api.id}")
    IO.puts("   Name: #{ai_api.name}")
    IO.puts("   Provider: #{ai_api.provider}")
    IO.puts("   Model: #{ai_api.model_name}")
    IO.puts("   Base URL: #{ai_api.base_url}")
    IO.puts("   Active: #{ai_api.is_active}")
    IO.puts("   Default: #{ai_api.is_default}")

  {:error, changeset} ->
    IO.puts("❌ Failed to add qwen3:1.7b model:")
    IO.inspect(changeset.errors)
end
