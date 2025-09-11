defmodule AiChatWeb.AdminComponents do
  @moduledoc """
  Reusable admin components for CRUD operations.
  """
  use Phoenix.Component

  @doc """
  Renders a standard admin page header with title, description, and back button.
  """
  attr :title, :string, required: true
  attr :description, :string, required: true
  attr :back_path, :string, required: true
  attr :back_text, :string, required: true
  attr :action_button, :any, default: nil

  def admin_page_header(assigns) do
    ~H"""
    <div class="sm:flex sm:items-center">
      <div class="sm:flex-auto">
        <h1 class="text-2xl font-semibold text-base-content"><%= @title %></h1>
        <p class="mt-2 text-sm text-base-content/80">
          <%= @description %>
        </p>
      </div>
      <div class="mt-4 sm:mt-0 sm:ml-16 sm:flex-none">
        <%= if @action_button do %>
          <div class="flex space-x-3">
            <.link href={@back_path} class="btn btn-outline">
              <%= @back_text %>
            </.link>
            <%= @action_button %>
          </div>
        <% else %>
          <.link href={@back_path} class="btn btn-outline">
            <%= @back_text %>
          </.link>
        <% end %>
      </div>
    </div>
    """
  end

  @doc """
  Renders a standard admin form with consistent styling.
  """
  attr :form, :any, required: true
  attr :action, :string, required: true
  attr :submit_text, :string, default: "Save"
  attr :cancel_path, :string, required: true
  attr :cancel_text, :string, default: "Cancel"

  slot :inner_block, required: true

  def admin_form(assigns) do
    ~H"""
    <div class="mt-8">
      <div class="card bg-base-200 shadow-xl">
        <div class="card-body">
          <.form for={@form} action={@action} class="space-y-6">
            <%= render_slot(@inner_block) %>

            <div class="flex justify-end space-x-3 pt-6 border-t border-base-300">
              <.link href={@cancel_path} class="btn btn-outline">
                <%= @cancel_text %>
              </.link>
              <button type="submit" class="btn btn-primary">
                <%= @submit_text %>
              </button>
            </div>
          </.form>
        </div>
      </div>
    </div>
    """
  end

  @doc """
  Renders a standard admin table with consistent styling.
  """
  attr :title, :string, required: true
  attr :new_path, :string, required: true
  attr :new_text, :string, default: "Add New"

  slot :inner_block, required: true

  def admin_table(assigns) do
    ~H"""
    <div class="sm:flex sm:items-center">
      <div class="sm:flex-auto">
        <h1 class="text-2xl font-semibold text-base-content"><%= @title %></h1>
      </div>
      <div class="mt-4 sm:mt-0 sm:ml-16 sm:flex-none">
        <.link href={@new_path} class="btn btn-primary">
          <%= @new_text %>
        </.link>
      </div>
    </div>

    <div class="mt-8">
      <div class="card bg-base-200 shadow-xl">
        <div class="card-body p-0">
          <div class="overflow-x-auto">
            <table class="table table-zebra w-full">
              <%= render_slot(@inner_block) %>
            </table>
          </div>
        </div>
      </div>
    </div>
    """
  end

  @doc """
  Renders a status badge with consistent styling.
  """
  attr :status, :boolean, required: true
  attr :active_text, :string, default: "Active"
  attr :inactive_text, :string, default: "Inactive"

  def status_badge(assigns) do
    ~H"""
    <span class={[
      "inline-flex px-2 py-1 text-xs font-semibold rounded-full w-fit",
      if(@status, do: "bg-green-100 text-green-800 dark:bg-green-900/20 dark:text-green-400", else: "bg-red-100 text-red-800 dark:bg-red-900/20 dark:text-red-400")
    ]}>
      <%= if @status, do: @active_text, else: @inactive_text %>
    </span>
    """
  end

  @doc """
  Renders a default badge for special statuses.
  """
  attr :text, :string, required: true
  attr :color, :string, default: "blue"

  def default_badge(assigns) do
    assigns = assign(assigns, :color_classes, get_color_classes(assigns.color))

    ~H"""
    <span class={["inline-flex px-2 py-1 text-xs font-semibold rounded-full w-fit", @color_classes]}>
      <%= @text %>
    </span>
    """
  end

  defp get_color_classes(color) do
    case color do
      "blue" -> "bg-blue-100 text-blue-800 dark:bg-blue-900/20 dark:text-blue-400"
      "green" -> "bg-green-100 text-green-800 dark:bg-green-900/20 dark:text-green-400"
      "red" -> "bg-red-100 text-red-800 dark:bg-red-900/20 dark:text-red-400"
      "yellow" -> "bg-yellow-100 text-yellow-800 dark:bg-yellow-900/20 dark:text-yellow-400"
      _ -> "bg-gray-100 text-gray-800 dark:bg-gray-900/20 dark:text-gray-400"
    end
  end

  @doc """
  Renders action buttons for table rows.
  """
  attr :edit_path, :string, required: true
  attr :delete_path, :string, required: true
  attr :item_name, :string, required: true

  def table_actions(assigns) do
    ~H"""
    <div class="flex space-x-2">
      <.link href={@edit_path} class="btn btn-ghost btn-sm">
        Edit
      </.link>
      <.link
        href={@delete_path}
        method="delete"
        data-confirm={"Are you sure you want to delete this #{@item_name}?"}
        class="btn btn-ghost btn-sm text-error hover:bg-error hover:text-error-content"
      >
        Delete
      </.link>
    </div>
    """
  end
end
