defmodule AiChatWeb.AdminDashboardLive do
  use AiChatWeb, :live_view
  alias AiChat.Analytics

  on_mount AiChatWeb.LiveAuth

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(AiChat.PubSub, "admin_updates")
    end

    current_user = socket.assigns.current_user

    # Check if user has admin access
    if is_nil(current_user) or not AiChat.Accounts.Permissions.has_admin_access?(current_user) do
      {:halt, redirect(socket, to: "/")}
    else
      socket = assign(socket, current_user: current_user, current_page: "dashboard")
      socket = load_dashboard_data(socket)

      {:ok, socket, layout: {AiChatWeb.Layouts, :admin}}
    end
  end

  @impl true
  def handle_info({:admin_update, _resource_type, _action}, socket) do
    # Refresh dashboard data when any admin resource is updated
    socket = load_dashboard_data(socket)
    {:noreply, socket}
  end

  @impl true
  def handle_event("refresh", _params, socket) do
    socket = load_dashboard_data(socket)
    {:noreply, put_flash(socket, :info, "Dashboard data refreshed")}
  end

  # Load dashboard statistics and data
  defp load_dashboard_data(socket) do
    # Test each function individually to find the problematic one
    try do
      total_users = Analytics.get_total_users()
      total_conversations = Analytics.get_total_conversations()
      total_messages = Analytics.get_total_messages()
      conversations_today = Analytics.get_conversations_today()
      messages_today = Analytics.get_messages_today()

      # Test recent activity
      recent_activity_data = Analytics.get_recent_activity()
      recent_activity = format_recent_activity(recent_activity_data)

      # Test weekly stats
      weekly_stats = Analytics.get_weekly_usage_stats()
      weekly_usage = format_weekly_usage(weekly_stats)

      stats = %{
        total_users: total_users,
        total_conversations: total_conversations,
        total_messages: total_messages,
        conversations_today: conversations_today,
        messages_today: messages_today,
        recent_activity: recent_activity,
        weekly_usage: weekly_usage
      }

      assign(socket, stats: stats)
    rescue
      error ->
        IO.inspect(error, label: "Error in load_dashboard_data")
        # Fallback to minimal stats
        stats = %{
          total_users: 0,
          total_conversations: 0,
          total_messages: 0,
          conversations_today: 0,
          messages_today: 0,
          recent_activity: [],
          weekly_usage: []
        }
        assign(socket, stats: stats)
    end
  end

  # Format recent activity for display
  defp format_recent_activity(activities) do
    Enum.map(activities, fn activity ->
      %{
        description: "#{activity.user_name} #{get_activity_description(activity.type)}",
        timestamp: format_timestamp(activity.created_at)
      }
    end)
  end

  defp get_activity_description("conversation"), do: "started a conversation"
  defp get_activity_description("user_registration"), do: "registered"
  defp get_activity_description(_), do: "performed an action"

  defp format_timestamp(datetime) do
    datetime
    |> DateTime.to_naive()
    |> NaiveDateTime.to_string()
    |> String.slice(0, 16)  # Remove seconds and microseconds
  end

  # Format weekly usage data for display
  defp format_weekly_usage(weekly_stats) do
    # Combine messages and conversations per day
    messages_map = Map.new(weekly_stats.messages_per_day, &{&1.date, &1.count})
    conversations_map = Map.new(weekly_stats.conversations_per_day, &{&1.date, &1.count})

    # Get all unique dates
    all_dates = MapSet.union(
      MapSet.new(weekly_stats.messages_per_day, & &1.date),
      MapSet.new(weekly_stats.conversations_per_day, & &1.date)
    )
    |> MapSet.to_list()
    |> Enum.sort()

    Enum.map(all_dates, fn date ->
      %{
        date: Date.to_string(date),
        messages: Map.get(messages_map, date, 0),
        conversations: Map.get(conversations_map, date, 0)
      }
    end)
  end

end
