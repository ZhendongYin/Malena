defmodule AiChatWeb.Layouts do
  @moduledoc """
  This module holds layouts and related functionality
  used by your application.
  """
  use AiChatWeb, :html

  # Embed all files in layouts/* within this module.
  # The default root.html.heex file contains the HTML
  # skeleton of your application, namely HTML headers
  # and other static content.
  embed_templates "layouts/*"


  @doc """
  Shows the flash group with standard titles and content.

  ## Examples

      <.flash_group flash={@flash} />
  """
  attr :flash, :map, required: true, doc: "the map of flash messages"
  attr :id, :string, default: "flash-group", doc: "the optional id of flash container"

  def flash_group(assigns) do
    ~H"""
    <div id={@id} aria-live="polite">
      <.flash kind={:info} flash={@flash} />
      <.flash kind={:error} flash={@flash} />
    </div>
    """
  end

  @doc """
  Admin sidebar component.
  """
  attr :current_page, :string, required: true, doc: "current page identifier"
  attr :user, :map, required: true, doc: "current user"

  def admin_sidebar(assigns) do
    ~H"""
    <div class="hidden lg:flex lg:w-64 lg:flex-col lg:fixed lg:inset-y-0">
      <div class="flex flex-col flex-grow bg-base-200 border-r border-base-300 pt-5 pb-4 overflow-y-auto">
        <!-- Logo -->
        <div class="flex items-center flex-shrink-0 px-4">
          <svg class="h-8 w-8 text-primary" fill="currentColor" viewBox="0 0 20 20">
            <path d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"/>
          </svg>
          <span class="ml-2 text-xl font-bold text-base-content">AI Chat Admin</span>
        </div>

        <!-- Navigation Menu -->
        <div class="mt-5 flex-grow flex flex-col">
          <nav class="flex-1 px-2 space-y-1">
            <.link
              href={~p"/admin/dashboard"}
              class={[
                "group flex items-center px-2 py-2 text-sm font-medium rounded-md transition-colors",
                if(@current_page == "dashboard",
                  do: "bg-primary text-primary-content",
                  else: "text-base-content hover:bg-base-300 hover:text-base-content"
                )
              ]}
            >
              <.icon name="hero-chart-bar-square" class="mr-3 h-5 w-5" />
              Dashboard
            </.link>

            <.link
              :if={AiChat.Accounts.Permissions.can_manage_users?(@user)}
              href={~p"/admin/users"}
              class={[
                "group flex items-center px-2 py-2 text-sm font-medium rounded-md transition-colors",
                if(@current_page == "users",
                  do: "bg-primary text-primary-content",
                  else: "text-base-content hover:bg-base-300 hover:text-base-content"
                )
              ]}
            >
              <.icon name="hero-users" class="mr-3 h-5 w-5" />
              Users
            </.link>

            <.link
              :if={AiChat.Accounts.Permissions.has_permission?(@user, "manage_departments")}
              href={~p"/admin/departments"}
              class={[
                "group flex items-center px-2 py-2 text-sm font-medium rounded-md transition-colors",
                if(@current_page == "departments",
                  do: "bg-primary text-primary-content",
                  else: "text-base-content hover:bg-base-300 hover:text-base-content"
                )
              ]}
            >
              <.icon name="hero-building-office-2" class="mr-3 h-5 w-5" />
              Departments
            </.link>

            <.link
              :if={AiChat.Accounts.Permissions.has_permission?(@user, "manage_roles")}
              href={~p"/admin/roles"}
              class={[
                "group flex items-center px-2 py-2 text-sm font-medium rounded-md transition-colors",
                if(@current_page == "roles",
                  do: "bg-primary text-primary-content",
                  else: "text-base-content hover:bg-base-300 hover:text-base-content"
                )
              ]}
            >
              <.icon name="hero-shield-check" class="mr-3 h-5 w-5" />
              Roles
            </.link>

            <.link
              :if={AiChat.Accounts.Permissions.can_manage_prompts?(@user)}
              href={~p"/admin/prompts"}
              class={[
                "group flex items-center px-2 py-2 text-sm font-medium rounded-md transition-colors",
                if(@current_page == "prompts",
                  do: "bg-primary text-primary-content",
                  else: "text-base-content hover:bg-base-300 hover:text-base-content"
                )
              ]}
            >
              <.icon name="hero-chat-bubble-left-right" class="mr-3 h-5 w-5" />
              Prompts
            </.link>

            <.link
              :if={AiChat.Accounts.Permissions.can_manage_knowledge_bases?(@user)}
              href={~p"/admin/knowledge-bases"}
              class={[
                "group flex items-center px-2 py-2 text-sm font-medium rounded-md transition-colors",
                if(@current_page == "knowledge-bases",
                  do: "bg-primary text-primary-content",
                  else: "text-base-content hover:bg-base-300 hover:text-base-content"
                )
              ]}
            >
              <.icon name="hero-book-open" class="mr-3 h-5 w-5" />
              Knowledge Bases
            </.link>

            <.link
              :if={AiChat.Accounts.Permissions.can_manage_ai_apis?(@user)}
              href={~p"/admin/ai-apis"}
              class={[
                "group flex items-center px-2 py-2 text-sm font-medium rounded-md transition-colors",
                if(@current_page == "ai-apis",
                  do: "bg-primary text-primary-content",
                  else: "text-base-content hover:bg-base-300 hover:text-base-content"
                )
              ]}
            >
              <.icon name="hero-cpu-chip" class="mr-3 h-5 w-5" />
              AI APIs
            </.link>
          </nav>
        </div>

        <!-- User Info at Bottom -->
        <div class="flex-shrink-0 flex border-t border-base-300 p-4">
          <div class="flex items-center">
            <div class="w-8 h-8 rounded-full bg-primary text-primary-content flex items-center justify-center">
              <span class="text-xs font-medium">
                <%= if @user, do: String.first(@user.name), else: "G" %>
              </span>
            </div>
            <div class="ml-3">
              <p class="text-sm font-medium text-base-content">
                <%= if @user, do: @user.name, else: "Guest" %>
              </p>
              <p class="text-xs text-base-content/70">
                <%= if @user do %>
                  <%= if @user.role, do: @user.role.name, else: "No Role" %>
                <% else %>
                  No Role
                <% end %>
              </p>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  @doc """
  Admin navigation component for all admin pages.
  """
  attr :current_page, :string, required: true, doc: "current page identifier"
  attr :user, :map, required: true, doc: "current user"

  def admin_nav(assigns) do
    ~H"""
    <nav class="bg-base-200 border-b border-base-300 lg:ml-64">
      <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div class="flex justify-between h-16">
          <!-- Page Title -->
          <div class="flex items-center">
            <h1 class="text-lg sm:text-xl font-bold text-base-content">
              <%= case @current_page do %>
                <% "dashboard" -> %>Dashboard
                <% "users" -> %>Users
                <% "departments" -> %>Departments
                <% "roles" -> %>Roles
                <% "prompts" -> %>Prompts
                <% "knowledge-bases" -> %>Knowledge Bases
                <% "ai-apis" -> %>AI APIs
                <% _ -> %>Admin
              <% end %>
            </h1>
          </div>

          <!-- Right Side: Theme Toggle and Mobile Menu -->
          <div class="flex items-center space-x-4">
            <!-- Theme Toggle -->
            <div class="flex-shrink-0">
              <.theme_toggle />
            </div>

            <!-- Mobile Menu Button -->
            <div class="lg:hidden">
              <div class="dropdown dropdown-end">
                <div tabindex="0" role="button" class="btn btn-ghost btn-sm">
                  <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 6h16M4 12h16M4 18h16"></path>
                  </svg>
                </div>
                <ul tabindex="0" class="menu menu-sm dropdown-content bg-base-100 rounded-box z-[1] mt-3 w-52 p-2 shadow border border-base-300">
                  <li>
                    <.link href={~p"/admin/dashboard"} class={if @current_page == "dashboard", do: "text-primary", else: "text-base-content"}>
                      Dashboard
                    </.link>
                  </li>
                  <li :if={AiChat.Accounts.Permissions.can_manage_users?(@user)}>
                    <.link href={~p"/admin/users"} class={if @current_page == "users", do: "text-primary", else: "text-base-content"}>
                      Users
                    </.link>
                  </li>
                  <li :if={AiChat.Accounts.Permissions.has_permission?(@user, "manage_departments")}>
                    <.link href={~p"/admin/departments"} class={if @current_page == "departments", do: "text-primary", else: "text-base-content"}>
                      Departments
                    </.link>
                  </li>
                  <li :if={AiChat.Accounts.Permissions.has_permission?(@user, "manage_roles")}>
                    <.link href={~p"/admin/roles"} class={if @current_page == "roles", do: "text-primary", else: "text-base-content"}>
                      Roles
                    </.link>
                  </li>
                  <li :if={AiChat.Accounts.Permissions.can_manage_prompts?(@user)}>
                    <.link href={~p"/admin/prompts"} class={if @current_page == "prompts", do: "text-primary", else: "text-base-content"}>
                      Prompts
                    </.link>
                  </li>
                  <li :if={AiChat.Accounts.Permissions.can_manage_knowledge_bases?(@user)}>
                    <.link href={~p"/admin/knowledge-bases"} class={if @current_page == "knowledge-bases", do: "text-primary", else: "text-base-content"}>
                      Knowledge Bases
                    </.link>
                  </li>
                  <li :if={AiChat.Accounts.Permissions.can_manage_ai_apis?(@user)}>
                    <.link href={~p"/admin/ai-apis"} class={if @current_page == "ai-apis", do: "text-primary", else: "text-base-content"}>
                      AI APIs
                    </.link>
                  </li>
                  <li class="divider"></li>
                  <li>
                    <div class="flex items-center justify-center p-2">
                      <.theme_toggle />
                    </div>
                  </li>
                  <li class="divider"></li>
                  <li>
                    <.link href={~p"/logout"} method="delete" class="text-error">
                      Sign Out
                    </.link>
                  </li>
                </ul>
              </div>
            </div>

            <!-- Desktop Sign Out Button -->
            <div class="hidden lg:block">
              <.link
                href={~p"/logout"}
                method="delete"
                class="btn btn-error btn-sm"
              >
                Sign Out
              </.link>
            </div>
          </div>
        </div>
      </div>
    </nav>
    """
  end

  @doc """
  Provides dark vs light theme toggle based on themes defined in app.css.

  See <head> in root.html.heex which applies the theme before page load.
  """
  def theme_toggle(assigns) do
    ~H"""
    <div class="relative flex flex-row items-center border border-base-300 bg-base-300 rounded-full p-0.5 w-20 h-8">
      <div class="absolute w-1/3 h-full rounded-full border border-base-200 bg-base-100 brightness-200 left-0 [[data-theme=system]_&]:left-0 [[data-theme=light]_&]:left-1/3 [[data-theme=dark]_&]:left-2/3 transition-[left]" />

      <button
        class="flex p-1 cursor-pointer w-1/3 relative z-10 justify-center"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="system"
      >
        <.icon name="hero-computer-desktop-micro" class="size-3 opacity-75 hover:opacity-100" />
      </button>

      <button
        class="flex p-1 cursor-pointer w-1/3 relative z-10 justify-center"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="light"
      >
        <.icon name="hero-sun-micro" class="size-3 opacity-75 hover:opacity-100" />
      </button>

      <button
        class="flex p-1 cursor-pointer w-1/3 relative z-10 justify-center"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="dark"
      >
        <.icon name="hero-moon-micro" class="size-3 opacity-75 hover:opacity-100" />
      </button>
    </div>
    """
  end
end
