# Test script to verify real-time updates
# Run this in IEx: iex -S mix

# Subscribe to admin updates
Phoenix.PubSub.subscribe(AiChat.PubSub, "admin_updates")

# Test broadcasting an update
Phoenix.PubSub.broadcast(AiChat.PubSub, "admin_updates", {:admin_update, "user", "created"})

# Check if we receive the message
receive do
  {:admin_update, resource_type, action} ->
    IO.puts("Received update: #{resource_type} #{action}")
after
  1000 ->
    IO.puts("No message received")
end
