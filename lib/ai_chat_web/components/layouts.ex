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

      <.flash
        id="client-error"
        kind={:error}
        title={gettext("We can't find the internet")}
        phx-disconnected={show(".phx-client-error #client-error") |> JS.remove_attribute("hidden")}
        phx-connected={hide("#client-error") |> JS.set_attribute({"hidden", ""})}
        hidden
      >
        {gettext("Attempting to reconnect")}
        <.icon name="hero-arrow-path" class="ml-1 size-3 motion-safe:animate-spin" />
      </.flash>

      <.flash
        id="server-error"
        kind={:error}
        title={gettext("Something went wrong!")}
        phx-disconnected={show(".phx-server-error #server-error") |> JS.remove_attribute("hidden")}
        phx-connected={hide("#server-error") |> JS.set_attribute({"hidden", ""})}
        hidden
      >
        {gettext("Attempting to reconnect")}
        <.icon name="hero-arrow-path" class="ml-1 size-3 motion-safe:animate-spin" />
      </.flash>
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
    <nav class="bg-base-200 border-b border-base-300">
      <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div class="flex justify-between h-16">
          <!-- Logo and Title -->
          <div class="flex items-center">
            <div class="flex-shrink-0">
              <h1 class="text-lg sm:text-xl font-bold text-base-content">AI Chat Admin</h1>
            </div>

            <!-- Desktop Navigation Menu -->
            <div class="hidden lg:ml-10 lg:flex lg:items-baseline lg:space-x-2">
              <.link
                href={~p"/admin/dashboard"}
                class={if @current_page == "dashboard", do: "btn btn-primary btn-sm", else: "btn btn-ghost btn-sm"}
              >
                Dashboard
              </.link>
              <.link
                :if={AiChat.Accounts.Permissions.can_manage_users?(@user)}
                href={~p"/admin/users"}
                class={if @current_page == "users", do: "btn btn-primary btn-sm", else: "btn btn-ghost btn-sm"}
              >
                Users
              </.link>
              <.link
                :if={AiChat.Accounts.Permissions.has_permission?(@user, "manage_departments")}
                href={~p"/admin/departments"}
                class={if @current_page == "departments", do: "btn btn-primary btn-sm", else: "btn btn-ghost btn-sm"}
              >
                Departments
              </.link>
              <.link
                :if={AiChat.Accounts.Permissions.has_permission?(@user, "manage_roles")}
                href={~p"/admin/roles"}
                class={if @current_page == "roles", do: "btn btn-primary btn-sm", else: "btn btn-ghost btn-sm"}
              >
                Roles
              </.link>
              <.link
                :if={AiChat.Accounts.Permissions.can_manage_prompts?(@user)}
                href={~p"/admin/prompts"}
                class={if @current_page == "prompts", do: "btn btn-primary btn-sm", else: "btn btn-ghost btn-sm"}
              >
                Prompts
              </.link>
              <.link
                :if={AiChat.Accounts.Permissions.can_manage_knowledge_bases?(@user)}
                href={~p"/admin/knowledge-bases"}
                class={if @current_page == "knowledge-bases", do: "btn btn-primary btn-sm", else: "btn btn-ghost btn-sm"}
              >
                Knowledge Bases
              </.link>
              <.link
                :if={AiChat.Accounts.Permissions.can_manage_ai_apis?(@user)}
                href={~p"/admin/ai-apis"}
                class={if @current_page == "ai-apis", do: "btn btn-primary btn-sm", else: "btn btn-ghost btn-sm"}
              >
                AI APIs
              </.link>
            </div>
          </div>

          <!-- Right Side: Theme Toggle, User Info, and Mobile Menu -->
          <div class="flex items-center space-x-2 sm:space-x-4">
            <!-- Theme Toggle -->
            <div class="hidden sm:block">
              <.theme_toggle />
            </div>

            <!-- User Info (Hidden on very small screens) -->
            <div class="hidden md:block">
              <%= if @user do %>
                <div class="text-sm text-base-content">
                  Welcome, <span class="font-medium"><%= @user.name %></span>
                </div>
                <div class="text-xs text-base-content/70">
                  <%= if @user.department, do: @user.department.name, else: "No Department" %> •
                  <%= if @user.role, do: @user.role.name, else: "No Role" %>
                </div>
              <% else %>
                <div class="text-sm text-base-content">
                  Welcome, <span class="font-medium">Guest</span>
                </div>
                <div class="text-xs text-base-content/70">
                  No Department • No Role
                </div>
              <% end %>
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
    <div class="card relative flex flex-row items-center border-2 border-base-300 bg-base-300 rounded-full">
      <div class="absolute w-1/3 h-full rounded-full border-1 border-base-200 bg-base-100 brightness-200 left-0 [[data-theme=system]_&]:left-0 [[data-theme=light]_&]:left-1/3 [[data-theme=dark]_&]:left-2/3 transition-[left]" />

      <button
        class="flex p-2 cursor-pointer w-1/3"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="system"
      >
        <.icon name="hero-computer-desktop-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>

      <button
        class="flex p-2 cursor-pointer w-1/3"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="light"
      >
        <.icon name="hero-sun-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>

      <button
        class="flex p-2 cursor-pointer w-1/3"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="dark"
      >
        <.icon name="hero-moon-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>
    </div>
    """
  end
end
