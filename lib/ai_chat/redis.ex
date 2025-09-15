defmodule AiChat.Redis do
  @moduledoc """
  Redis connection and operations module.
  """

  use GenServer
  require Logger

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(opts) do
    host = Keyword.get(opts, :host, "localhost")
    port = Keyword.get(opts, :port, 6379)
    password = Keyword.get(opts, :password)
    database = Keyword.get(opts, :database, 0)
    timeout = Keyword.get(opts, :timeout, 5000)

    # Start Redix connection
    {:ok, conn} = Redix.start_link(
      host: host,
      port: port,
      password: password,
      database: database,
      timeout: timeout,
      name: :redix
    )

    Logger.info("Redis connected to #{host}:#{port}")
    {:ok, %{conn: conn}}
  end

  @doc """
  Execute a Redis command.
  """
  def command(command) do
    Redix.command(:redix, command)
  end

  @doc """
  Execute a Redis pipeline.
  """
  def pipeline(commands) do
    Redix.pipeline(:redix, commands)
  end

  @doc """
  Set a key-value pair with optional TTL.
  """
  def set(key, value, ttl \\ nil) do
    case ttl do
      nil -> command(["SET", key, value])
      ttl -> command(["SETEX", key, ttl, value])
    end
  end

  @doc """
  Get a value by key.
  """
  def get(key) do
    case command(["GET", key]) do
      {:ok, nil} -> nil
      {:ok, value} -> value
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Delete a key.
  """
  def delete(key) do
    command(["DEL", key])
  end

  @doc """
  Check if a key exists.
  """
  def exists(key) do
    case command(["EXISTS", key]) do
      {:ok, 1} -> true
      {:ok, 0} -> false
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Set expiration for a key.
  """
  def expire(key, seconds) do
    command(["EXPIRE", key, seconds])
  end

  @doc """
  Get TTL for a key.
  """
  def ttl(key) do
    command(["TTL", key])
  end

  @doc """
  Increment a counter.
  """
  def incr(key) do
    command(["INCR", key])
  end

  @doc """
  Increment a counter by amount.
  """
  def incrby(key, amount) do
    command(["INCRBY", key, amount])
  end

  @doc """
  Add member to a set.
  """
  def sadd(key, member) do
    command(["SADD", key, member])
  end

  @doc """
  Get all members of a set.
  """
  def smembers(key) do
    case command(["SMEMBERS", key]) do
      {:ok, members} -> members
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Remove member from a set.
  """
  def srem(key, member) do
    command(["SREM", key, member])
  end

  @doc """
  Check if member exists in set.
  """
  def sismember(key, member) do
    case command(["SISMEMBER", key, member]) do
      {:ok, 1} -> true
      {:ok, 0} -> false
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Push to list (left).
  """
  def lpush(key, value) do
    command(["LPUSH", key, value])
  end

  @doc """
  Push to list (right).
  """
  def rpush(key, value) do
    command(["RPUSH", key, value])
  end

  @doc """
  Pop from list (left).
  """
  def lpop(key) do
    case command(["LPOP", key]) do
      {:ok, nil} -> nil
      {:ok, value} -> value
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Pop from list (right).
  """
  def rpop(key) do
    case command(["RPOP", key]) do
      {:ok, nil} -> nil
      {:ok, value} -> value
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Get list range.
  """
  def lrange(key, start, stop) do
    case command(["LRANGE", key, start, stop]) do
      {:ok, values} -> values
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Get list length.
  """
  def llen(key) do
    case command(["LLEN", key]) do
      {:ok, length} -> length
      {:error, reason} -> {:error, reason}
    end
  end
end
