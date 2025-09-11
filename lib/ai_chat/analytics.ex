defmodule AiChat.Analytics do
  @moduledoc """
  Analytics context for real-time statistics and metrics.
  """

  import Ecto.Query, warn: false
  alias AiChat.Repo

  @doc """
  Get real-time dashboard statistics.
  """
  def get_dashboard_stats do
    %{
      # Basic counts
      total_users: get_total_users(),
      total_departments: get_total_departments(),
      total_roles: get_total_roles(),
      total_prompts: get_total_prompts(),
      total_knowledge_bases: get_total_knowledge_bases(),
      total_ai_apis: get_total_ai_apis(),

      # Real-time metrics
      active_users_today: get_active_users_today(),
      active_users_this_week: get_active_users_this_week(),
      total_conversations: get_total_conversations(),
      conversations_today: get_conversations_today(),
      total_messages: get_total_messages(),
      messages_today: get_messages_today(),
      active_ai_apis: get_active_ai_apis(),

      # System health
      system_health: get_system_health()
    }
  end

  # Basic counts
  def get_total_users do
    from(u in AiChat.Accounts.User)
    |> Repo.aggregate(:count)
  end

  def get_total_departments do
    from(d in AiChat.Organizations.Department)
    |> Repo.aggregate(:count)
  end

  def get_total_roles do
    from(r in AiChat.Organizations.Role)
    |> Repo.aggregate(:count)
  end

  def get_total_prompts do
    from(p in AiChat.Prompts.Prompt)
    |> Repo.aggregate(:count)
  end

  def get_total_knowledge_bases do
    from(kb in AiChat.KnowledgeBases.KnowledgeBase)
    |> Repo.aggregate(:count)
  end

  def get_total_ai_apis do
    from(a in AiChat.AiApis.AiApi)
    |> Repo.aggregate(:count)
  end

  # Real-time metrics
  defp get_active_users_today do
    today = Date.utc_today()
    start_of_day = DateTime.new!(today, ~T[00:00:00], "Etc/UTC")
    end_of_day = DateTime.new!(today, ~T[23:59:59], "Etc/UTC")

    from(u in AiChat.Accounts.User,
      where: u.last_login_at >= ^start_of_day and u.last_login_at <= ^end_of_day
    )
    |> Repo.aggregate(:count)
  end

  defp get_active_users_this_week do
    week_ago = DateTime.utc_now() |> DateTime.add(-7, :day)

    from(u in AiChat.Accounts.User,
      where: u.last_login_at >= ^week_ago
    )
    |> Repo.aggregate(:count)
  end

  def get_total_conversations do
    from(c in AiChat.Chat.Conversation)
    |> Repo.aggregate(:count)
  end

  def get_conversations_today do
    today = Date.utc_today()
    start_of_day = DateTime.new!(today, ~T[00:00:00], "Etc/UTC")
    end_of_day = DateTime.new!(today, ~T[23:59:59], "Etc/UTC")

    from(c in AiChat.Chat.Conversation,
      where: c.inserted_at >= ^start_of_day and c.inserted_at <= ^end_of_day
    )
    |> Repo.aggregate(:count)
  end

  def get_total_messages do
    from(m in AiChat.Chat.Message)
    |> Repo.aggregate(:count)
  end

  def get_messages_today do
    today = Date.utc_today()
    start_of_day = DateTime.new!(today, ~T[00:00:00], "Etc/UTC")
    end_of_day = DateTime.new!(today, ~T[23:59:59], "Etc/UTC")

    from(m in AiChat.Chat.Message,
      where: m.inserted_at >= ^start_of_day and m.inserted_at <= ^end_of_day
    )
    |> Repo.aggregate(:count)
  end

  defp get_active_ai_apis do
    # Since we removed is_active field, all APIs are considered active
    get_total_ai_apis()
  end

  # System health
  defp get_system_health do
    %{
      database_status: check_database_status(),
      ai_apis_status: check_ai_apis_status(),
      storage_status: check_storage_status()
    }
  end

  defp check_database_status do
    try do
      Repo.query!("SELECT 1")
      "healthy"
    rescue
      _ -> "unhealthy"
    end
  end

  defp check_ai_apis_status do
    active_apis = get_active_ai_apis()
    total_apis = get_total_ai_apis()

    cond do
      active_apis == 0 -> "critical"
      active_apis < total_apis -> "warning"
      true -> "healthy"
    end
  end

  defp check_storage_status do
    # This is a simplified check - in production you'd want to check actual disk space
    "healthy"
  end

  @doc """
  Get recent activity for the dashboard.
  """
  def get_recent_activity(limit \\ 10) do
    # Get recent conversations
    recent_conversations =
      from(c in AiChat.Chat.Conversation,
        join: u in AiChat.Accounts.User, on: c.user_id == u.id,
        order_by: [desc: c.inserted_at],
        limit: ^limit,
        select: %{
          type: "conversation",
          id: c.id,
          title: c.title,
          user_name: u.name,
          created_at: c.inserted_at
        }
      )
      |> Repo.all()

    # Get recent user registrations
    recent_users =
      from(u in AiChat.Accounts.User,
        order_by: [desc: u.inserted_at],
        limit: ^limit,
        select: %{
          type: "user_registration",
          id: u.id,
          title: "New user registered",
          user_name: u.name,
          created_at: u.inserted_at
        }
      )
      |> Repo.all()

    # Combine and sort by created_at
    (recent_conversations ++ recent_users)
    |> Enum.sort_by(& &1.created_at, {:desc, DateTime})
    |> Enum.take(limit)
  end

  @doc """
  Get usage statistics for the last 7 days.
  """
  def get_weekly_usage_stats do
    week_ago = DateTime.utc_now() |> DateTime.add(-7, :day)

    # Messages per day
    messages_per_day =
      from(m in AiChat.Chat.Message,
        where: m.inserted_at >= ^week_ago,
        select: %{
          date: fragment("DATE(?)", m.inserted_at),
          count: count(m.id)
        },
        group_by: [fragment("DATE(?)", m.inserted_at)],
        order_by: [fragment("DATE(?)", m.inserted_at)]
      )
      |> Repo.all()

    # Conversations per day
    conversations_per_day =
      from(c in AiChat.Chat.Conversation,
        where: c.inserted_at >= ^week_ago,
        select: %{
          date: fragment("DATE(?)", c.inserted_at),
          count: count(c.id)
        },
        group_by: [fragment("DATE(?)", c.inserted_at)],
        order_by: [fragment("DATE(?)", c.inserted_at)]
      )
      |> Repo.all()

    %{
      messages_per_day: messages_per_day,
      conversations_per_day: conversations_per_day
    }
  end
end
