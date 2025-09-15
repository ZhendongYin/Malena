defmodule AiChat.SessionManager do
  @moduledoc """
  Session management using Redis for distributed session storage.
  """

  require Logger

  @session_prefix "session:"
  @user_sessions_prefix "user_sessions:"
  @session_ttl 3600 # 1 hour

  @doc """
  Store session data in Redis.
  """
  def store_session(session_id, data, ttl \\ @session_ttl) do
    key = @session_prefix <> session_id
    encoded_data = Jason.encode!(data)

    case AiChat.Redis.set(key, encoded_data, ttl) do
      {:ok, "OK"} ->
        # Also store session ID for user lookup
        if user_id = data["user_id"] do
          user_key = @user_sessions_prefix <> to_string(user_id)
          AiChat.Redis.sadd(user_key, session_id)
          AiChat.Redis.expire(user_key, ttl)
        end
        :ok
      {:error, reason} ->
        Logger.error("Failed to store session: #{inspect(reason)}")
        {:error, reason}
    end
  end

  @doc """
  Retrieve session data from Redis.
  """
  def get_session(session_id) do
    key = @session_prefix <> session_id

    case AiChat.Redis.get(key) do
      nil -> nil
      encoded_data ->
        case Jason.decode(encoded_data) do
          {:ok, data} -> data
          {:error, reason} ->
            Logger.error("Failed to decode session data: #{inspect(reason)}")
            nil
        end
    end
  end

  @doc """
  Delete session from Redis.
  """
  def delete_session(session_id) do
    key = @session_prefix <> session_id

    # Get session data first to find user_id
    case get_session(session_id) do
      nil -> :ok
      data ->
        # Remove from user sessions
        if user_id = data["user_id"] do
          user_key = @user_sessions_prefix <> to_string(user_id)
          AiChat.Redis.srem(user_key, session_id)
        end

        # Delete session
        case AiChat.Redis.delete(key) do
          {:ok, _} -> :ok
          {:error, reason} ->
            Logger.error("Failed to delete session: #{inspect(reason)}")
            {:error, reason}
        end
    end
  end

  @doc """
  Get all sessions for a user.
  """
  def get_user_sessions(user_id) do
    user_key = @user_sessions_prefix <> to_string(user_id)

    case AiChat.Redis.smembers(user_key) do
      {:error, reason} ->
        Logger.error("Failed to get user sessions: #{inspect(reason)}")
        {:error, reason}
      session_ids ->
        # Filter out expired sessions
        valid_sessions = Enum.filter(session_ids, fn session_id ->
          case get_session(session_id) do
            nil -> false
            _ -> true
          end
        end)

        # Update user sessions set with only valid sessions
        if length(valid_sessions) != length(session_ids) do
          AiChat.Redis.delete(user_key)
          if length(valid_sessions) > 0 do
            AiChat.Redis.sadd(user_key, valid_sessions)
            AiChat.Redis.expire(user_key, @session_ttl)
          end
        end

        valid_sessions
    end
  end

  @doc """
  Delete all sessions for a user.
  """
  def delete_user_sessions(user_id) do
    case get_user_sessions(user_id) do
      {:error, reason} -> {:error, reason}
      session_ids ->
        # Delete all sessions
        Enum.each(session_ids, &delete_session/1)

        # Delete user sessions set
        user_key = @user_sessions_prefix <> to_string(user_id)
        AiChat.Redis.delete(user_key)

        :ok
    end
  end

  @doc """
  Extend session TTL.
  """
  def extend_session(session_id, ttl \\ @session_ttl) do
    key = @session_prefix <> session_id

    case AiChat.Redis.expire(key, ttl) do
      {:ok, 1} -> :ok
      {:ok, 0} -> {:error, :session_not_found}
      {:error, reason} ->
        Logger.error("Failed to extend session: #{inspect(reason)}")
        {:error, reason}
    end
  end

  @doc """
  Check if session exists and is valid.
  """
  def session_exists?(session_id) do
    key = @session_prefix <> session_id
    AiChat.Redis.exists(key)
  end

  @doc """
  Get session TTL.
  """
  def get_session_ttl(session_id) do
    key = @session_prefix <> session_id

    case AiChat.Redis.ttl(key) do
      {:ok, -1} -> :no_expiry
      {:ok, -2} -> :expired
      {:ok, ttl} -> ttl
      {:error, reason} ->
        Logger.error("Failed to get session TTL: #{inspect(reason)}")
        {:error, reason}
    end
  end

  @doc """
  Clean up expired sessions (can be called periodically).
  """
  def cleanup_expired_sessions do
    # This is a simple cleanup - in production you might want to use
    # Redis SCAN with pattern matching for better performance
    Logger.info("Cleaning up expired sessions...")
    :ok
  end

  @doc """
  Get session statistics.
  """
  def get_session_stats do
    # This would require Redis SCAN to get all session keys
    # For now, return basic info
    %{
      total_sessions: 0, # Would need to implement with SCAN
      active_users: 0    # Would need to implement with SCAN
    }
  end
end
