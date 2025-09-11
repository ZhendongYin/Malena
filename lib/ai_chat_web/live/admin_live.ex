defmodule AiChatWeb.AdminLive do
  @moduledoc """
  LiveView for admin pages with full CRUD functionality.
  """
  use AiChatWeb, :live_view


  alias AiChat.Accounts
  alias AiChat.Organizations
  alias AiChat.Prompts
  alias AiChat.KnowledgeBases
  alias AiChat.AiApis
  alias AiChat.Repo

  on_mount AiChatWeb.LiveAuth

  @impl true
  def mount(params, session, socket) do
    # Check if user has admin access
    user = socket.assigns.current_user
    if is_nil(user) do
      {:halt, redirect(socket, to: "/")}
    else
      if not AiChat.Accounts.Permissions.has_admin_access?(user) do
        {:halt, redirect(socket, to: "/")}
      else
        mount_continue(params, session, socket)
      end
    end
  end

  defp mount_continue(_params, _session, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(AiChat.PubSub, "admin_updates")
    end

    # Don't set default current_page here - let handle_params handle it
    socket = assign(socket, :action, :index)
    socket = assign(socket, :form, nil)
    socket = assign(socket, :editing_item, nil)

    {:ok, socket, layout: {AiChatWeb.Layouts, :admin}}
  end

  @impl true
  def handle_params(_params, url, socket) do
    # Extract current page and action from URL path
    {current_page, action} = case URI.parse(url).path do
      "/admin/users" -> {"users", :index}
      "/admin/users/new" -> {"users", :new}
      "/admin/departments" -> {"departments", :index}
      "/admin/departments/new" -> {"departments", :new}
      "/admin/roles" -> {"roles", :index}
      "/admin/roles/new" -> {"roles", :new}
      "/admin/prompts" -> {"prompts", :index}
      "/admin/prompts/new" -> {"prompts", :new}
      "/admin/knowledge-bases" -> {"knowledge-bases", :index}
      "/admin/knowledge-bases/new" -> {"knowledge-bases", :new}
      "/admin/ai-apis" -> {"ai-apis", :index}
      "/admin/ai-apis/new" -> {"ai-apis", :new}
      path when is_binary(path) ->
        # Handle edit routes with dynamic IDs
        cond do
          String.match?(path, ~r/^\/admin\/users\/\d+\/edit$/) ->
            id = String.split(path, "/") |> Enum.at(3)
            {"users", {:edit, id}}
          String.match?(path, ~r/^\/admin\/departments\/\d+\/edit$/) ->
            id = String.split(path, "/") |> Enum.at(3)
            {"departments", {:edit, id}}
          String.match?(path, ~r/^\/admin\/roles\/\d+\/edit$/) ->
            id = String.split(path, "/") |> Enum.at(3)
            {"roles", {:edit, id}}
          String.match?(path, ~r/^\/admin\/prompts\/\d+\/edit$/) ->
            id = String.split(path, "/") |> Enum.at(3)
            {"prompts", {:edit, id}}
          String.match?(path, ~r/^\/admin\/knowledge-bases\/\d+\/edit$/) ->
            id = String.split(path, "/") |> Enum.at(3)
            {"knowledge-bases", {:edit, id}}
          String.match?(path, ~r/^\/admin\/ai-apis\/\d+\/edit$/) ->
            id = String.split(path, "/") |> Enum.at(3)
            {"ai-apis", {:edit, id}}
          true -> {"users", :index}
        end
      _ -> {"users", :index}
    end

    socket = assign(socket, :current_page, current_page)
    socket = assign(socket, :action, action)

    # Load data based on action
    socket = case action do
      :index -> load_data_for_index(socket, current_page)
      :new -> load_data_for_new(socket, current_page)
      {:edit, id} -> load_data_for_edit(socket, current_page, id)
    end

    {:noreply, socket}
  end

  @impl true
  def handle_event("validate", %{"_target" => _target} = params, socket) do
    form = validate_form(socket, params)
    {:noreply, assign(socket, :form, form)}
  end

  @impl true
  def handle_event("save", params, socket) do
    case save_item(socket, params) do
      {:ok, _item} ->
        # Broadcast update to all connected clients
        Phoenix.PubSub.broadcast(AiChat.PubSub, "admin_updates", {:admin_update, "item_saved"})

        {:noreply,
         socket
         |> put_flash(:info, "Item saved successfully.")
         |> push_patch(to: ~p"/admin/#{socket.assigns.current_page}")}

      {:error, changeset} ->
        {:noreply, assign(socket, :form, changeset)}
    end
  end

  @impl true
  def handle_event("delete", %{"id" => id, "type" => type}, socket) do
    case delete_item(type, id) do
      {:ok, _} ->
        # Broadcast update to all connected clients
        Phoenix.PubSub.broadcast(AiChat.PubSub, "admin_updates", {:admin_update, "item_deleted"})

        {:noreply,
         socket
         |> put_flash(:info, "Item deleted successfully.")
         |> load_data_for_index(socket.assigns.current_page)}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Failed to delete item.")}
    end
  end

  @impl true
  def handle_event("toggle_status", %{"id" => id, "type" => type}, socket) do
    case toggle_status(type, id) do
      {:ok, _} ->
        # Broadcast update to all connected clients
        Phoenix.PubSub.broadcast(AiChat.PubSub, "admin_updates", {:admin_update, "status_toggled"})

        {:noreply, load_data_for_index(socket, socket.assigns.current_page)}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Failed to update status.")}
    end
  end

  @impl true
  def handle_event("set_default", %{"id" => id, "type" => "ai_api"}, socket) do
    case AiApis.set_default_ai_api(AiApis.get_ai_api!(id)) do
      {:ok, _} ->
        {:noreply, load_data_for_index(socket, "ai-apis")}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Failed to set default API.")}
    end
  end

  @impl true
  def handle_event("refresh", _params, socket) do
    socket = load_data_for_index(socket, socket.assigns.current_page)
    {:noreply, socket}
  end

  @impl true
  def handle_info({:admin_update, _message}, socket) do
    # Reload data when admin updates occur
    socket = load_data_for_index(socket, socket.assigns.current_page)
    {:noreply, socket}
  end

  # Helper functions
  defp load_data_for_index(socket, page) do
    case page do
      "users" -> load_users(socket)
      "departments" -> load_departments(socket)
      "roles" -> load_roles(socket)
      "prompts" -> load_prompts(socket)
      "knowledge-bases" -> load_knowledge_bases(socket)
      "ai-apis" -> load_ai_apis(socket)
    end
  end

  defp load_data_for_new(socket, page) do
    socket = load_data_for_index(socket, page)
    form = create_form_for_new(page)
    assign(socket, :form, form)
  end

  defp load_data_for_edit(socket, page, id) do
    socket = load_data_for_index(socket, page)
    {item, form} = create_form_for_edit(page, id)
    socket
    |> assign(:form, form)
    |> assign(:editing_item, item)
  end

  defp load_users(socket) do
    users = Accounts.list_users() |> Repo.preload([:department, :role])
    assign(socket, :users, users)
  end

  defp load_departments(socket) do
    departments = Organizations.list_departments() |> Repo.preload(:parent)
    assign(socket, :departments, departments)
  end

  defp load_roles(socket) do
    roles = Organizations.list_roles()
    assign(socket, :roles, roles)
  end

  defp load_prompts(socket) do
    prompts = Prompts.list_prompts()
    departments = Organizations.list_departments()
    roles = Organizations.list_roles()

    socket
    |> assign(:prompts, prompts)
    |> assign(:departments, departments)
    |> assign(:roles, roles)
  end

  defp load_knowledge_bases(socket) do
    knowledge_bases = KnowledgeBases.list_knowledge_bases()
    assign(socket, :knowledge_bases, knowledge_bases)
  end

  defp load_ai_apis(socket) do
    ai_apis = AiApis.list_ai_apis()
    assign(socket, :ai_apis, ai_apis)
  end

  defp create_form_for_new(page) do
    case page do
      "users" -> Accounts.change_user(%Accounts.User{})
      "departments" -> Organizations.change_department(%Organizations.Department{})
      "roles" -> Organizations.change_role(%Organizations.Role{})
      "prompts" -> Prompts.change_prompt(%Prompts.Prompt{})
      "knowledge-bases" -> KnowledgeBases.change_knowledge_base(%KnowledgeBases.KnowledgeBase{})
      "ai-apis" -> AiApis.change_ai_api(%AiApis.AiApi{})
    end
  end

  defp create_form_for_edit(page, id) do
    case page do
      "users" ->
        user = Accounts.get_user!(id)
        {user, Accounts.change_user(user)}
      "departments" ->
        dept = Organizations.get_department!(id)
        {dept, Organizations.change_department(dept)}
      "roles" ->
        role = Organizations.get_role!(id)
        {role, Organizations.change_role(role)}
      "prompts" ->
        prompt = Prompts.get_prompt!(id)
        {prompt, Prompts.change_prompt(prompt)}
      "knowledge-bases" ->
        kb = KnowledgeBases.get_knowledge_base!(id)
        {kb, KnowledgeBases.change_knowledge_base(kb)}
      "ai-apis" ->
        api = AiApis.get_ai_api!(id)
        {api, AiApis.change_ai_api(api)}
    end
  end

  defp validate_form(socket, params) do
    page = socket.assigns.current_page
    form_data = extract_form_data(params, page)

    case socket.assigns.action do
      :new ->
        changeset = create_changeset_for_new(page, form_data)
        to_form(changeset)

      {:edit, _id} ->
        changeset = create_changeset_for_edit(page, socket.assigns.editing_item, form_data)
        to_form(changeset)
    end
  end

  defp save_item(socket, params) do
    page = socket.assigns.current_page
    form_data = extract_form_data(params, page)

    case socket.assigns.action do
      :new ->
        create_item(page, form_data)

      {:edit, _id} ->
        update_item(page, socket.assigns.editing_item, form_data)
    end
  end

  defp extract_form_data(params, page) do
    case page do
      "users" -> params["user"] || %{}
      "departments" -> params["department"] || %{}
      "roles" -> params["role"] || %{}
      "prompts" -> params["prompt"] || %{}
      "knowledge-bases" -> params["knowledge_base"] || %{}
      "ai-apis" -> params["ai_api"] || %{}
    end
  end

  defp create_changeset_for_new(page, params) do
    case page do
      "users" -> Accounts.change_user(%Accounts.User{}, params)
      "departments" -> Organizations.change_department(%Organizations.Department{}, params)
      "roles" -> Organizations.change_role(%Organizations.Role{}, params)
      "prompts" -> Prompts.change_prompt(%Prompts.Prompt{}, params)
      "knowledge-bases" -> KnowledgeBases.change_knowledge_base(%KnowledgeBases.KnowledgeBase{}, params)
      "ai-apis" -> AiApis.change_ai_api(%AiApis.AiApi{}, params)
    end
  end

  defp create_changeset_for_edit(page, item, params) do
    case page do
      "users" -> Accounts.change_user(item, params)
      "departments" -> Organizations.change_department(item, params)
      "roles" -> Organizations.change_role(item, params)
      "prompts" -> Prompts.change_prompt(item, params)
      "knowledge-bases" -> KnowledgeBases.change_knowledge_base(item, params)
      "ai-apis" -> AiApis.change_ai_api(item, params)
    end
  end

  defp create_item(page, params) do
    case page do
      "users" -> Accounts.create_user(params)
      "departments" -> Organizations.create_department(params)
      "roles" -> Organizations.create_role(params)
      "prompts" -> Prompts.create_prompt(params)
      "knowledge-bases" -> KnowledgeBases.create_knowledge_base(params)
      "ai-apis" -> AiApis.create_ai_api(params)
    end
  end

  defp update_item(page, item, params) do
    case page do
      "users" -> Accounts.update_user(item, params)
      "departments" -> Organizations.update_department(item, params)
      "roles" -> Organizations.update_role(item, params)
      "prompts" -> Prompts.update_prompt(item, params)
      "knowledge-bases" -> KnowledgeBases.update_knowledge_base(item, params)
      "ai-apis" -> AiApis.update_ai_api(item, params)
    end
  end

  defp delete_item(type, id) do
    case type do
      "user" -> Accounts.delete_user(Accounts.get_user!(id))
      "department" -> Organizations.delete_department(Organizations.get_department!(id))
      "role" -> Organizations.delete_role(Organizations.get_role!(id))
      "prompt" -> Prompts.delete_prompt(Prompts.get_prompt!(id))
      "knowledge_base" -> KnowledgeBases.delete_knowledge_base(KnowledgeBases.get_knowledge_base!(id))
      "ai_api" -> AiApis.delete_ai_api(AiApis.get_ai_api!(id))
    end
  end

  defp toggle_status(type, id) do
    case type do
      "user" ->
        user = Accounts.get_user!(id)
        Accounts.update_user(user, %{is_active: !user.is_active})
      "department" ->
        dept = Organizations.get_department!(id)
        Organizations.update_department(dept, %{is_active: !dept.is_active})
      "role" ->
        role = Organizations.get_role!(id)
        Organizations.update_role(role, %{is_active: !role.is_active})
      "prompt" ->
        prompt = Prompts.get_prompt!(id)
        Prompts.update_prompt(prompt, %{is_active: !prompt.is_active})
      "knowledge_base" ->
        kb = KnowledgeBases.get_knowledge_base!(id)
        KnowledgeBases.update_knowledge_base(kb, %{is_active: !kb.is_active})
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <%= if @action == :index do %>
        <!-- Index view -->
        <div class="sm:flex sm:items-center">
          <div class="sm:flex-auto">
            <h1 class="text-2xl font-semibold text-base-content">
              <%= String.capitalize(@current_page) %>
            </h1>
            <p class="mt-2 text-sm text-base-content/80">
              <%= get_page_description(@current_page) %>
            </p>
          </div>
          <div class="mt-4 sm:mt-0 sm:ml-16 sm:flex-none">
            <div class="flex gap-2">
              <button
                phx-click="refresh"
                class="btn btn-outline border-base-content"
                title="Refresh data"
              >
                <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15"></path>
                </svg>
                Refresh
              </button>
              <.link
                href={~p"/admin/#{@current_page}/new"}
                class="btn btn-primary"
              >
                <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4"></path>
                </svg>
                Add <%= String.capitalize(@current_page) |> String.replace("-", " ") %>
              </.link>
            </div>
          </div>
        </div>

        <!-- Real-time Status Indicator -->
        <div class="mt-4">
          <div class="flex items-center text-sm text-base-content/70">
            <div class="w-2 h-2 bg-green-500 rounded-full mr-2 animate-pulse"></div>
            Live updates enabled
          </div>
        </div>

        <div class="mt-8">
          <%= render_table(@current_page, assigns) %>
        </div>
      <% else %>
        <!-- Form view -->
        <div class="max-w-2xl mx-auto">
          <div class="card bg-base-200 shadow-xl">
            <div class="card-body">
              <h2 class="card-title">
                <%= if @action == :new, do: "Create New", else: "Edit" %>
                <%= String.capitalize(@current_page) |> String.replace("-", " ") %>
              </h2>

              <.form for={@form} phx-submit="save" phx-change="validate" class="space-y-4">
                <%= if @current_page == "users" do %>
                  <div class="form-control">
                    <.input field={@form[:name]} type="text" label="Name" class="input input-bordered" />
                  </div>

                  <div class="form-control">
                    <.input field={@form[:email]} type="email" label="Email" class="input input-bordered" />
                  </div>

                  <div class="form-control">
                    <.input field={@form[:password]} type="password" label="Password" class="input input-bordered" />
                  </div>

                  <div class="form-control">
                    <label class="label">
                      <span class="label-text">Department</span>
                    </label>
                    <.input field={@form[:department_id]} type="select" options={[{"All Departments", ""} | Enum.map(@departments, &{&1.name, &1.id})]} class="select select-bordered" />
                  </div>

                  <div class="form-control">
                    <label class="label">
                      <span class="label-text">Role</span>
                    </label>
                    <.input field={@form[:role_id]} type="select" options={[{"All Roles", ""} | Enum.map(@roles, &{&1.name, &1.id})]} class="select select-bordered" />
                  </div>

                  <div class="form-control">
                    <label class="label cursor-pointer">
                      <span class="label-text">Active</span>
                      <.input field={@form[:is_active]} type="checkbox" class="toggle toggle-primary" />
                    </label>
                  </div>
                <% else %>
                  <div>Form fields for <%= @current_page %> not implemented yet</div>
                <% end %>

                <div class="card-actions justify-end">
                  <.link href={~p"/admin/#{@current_page}"} class="btn btn-ghost">
                    <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"></path>
                    </svg>
                    Cancel
                  </.link>
                  <button type="submit" class="btn btn-primary">
                    <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"></path>
                    </svg>
                    <%= if @action == :new, do: "Create", else: "Update" %>
                  </button>
                </div>
              </.form>
            </div>
          </div>
        </div>
      <% end %>
    </div>
    """
  end

  defp get_page_description(page) do
    case page do
      "users" -> "A list of all users in your account including their name, email, department, and role."
      "departments" -> "Manage organizational departments and their settings."
      "roles" -> "Define roles and permissions for different user types."
      "prompts" -> "Create and manage AI prompts for different departments and roles."
      "knowledge-bases" -> "Upload and manage knowledge base documents."
      "ai-apis" -> "Configure AI API endpoints and models."
      _ -> "Manage your account settings and data."
    end
  end

  defp render_table(page, assigns) do
    case page do
      "users" -> render_users_table(assigns)
      "departments" -> render_departments_table(assigns)
      "roles" -> render_roles_table(assigns)
      "prompts" -> render_prompts_table(assigns)
      "knowledge-bases" -> render_knowledge_bases_table(assigns)
      "ai-apis" -> render_ai_apis_table(assigns)
    end
  end

  defp render_users_table(assigns) do
    ~H"""
    <div class="card bg-base-200 shadow-xl">
      <div class="card-body">
        <h2 class="card-title">Users</h2>
        <div class="overflow-x-auto">
          <table class="table table-zebra w-full">
            <thead>
              <tr>
                <th>Name</th>
                <th>Email</th>
                <th>Department</th>
                <th>Role</th>
                <th>Status</th>
                <th>Actions</th>
              </tr>
            </thead>
            <tbody>
              <tr :for={user <- @users} id={"user-#{user.id}"}>
                <td><%= user.name %></td>
                <td><%= user.email %></td>
                <td><%= if user.department, do: user.department.name, else: "No Department" %></td>
                <td><%= if user.role, do: user.role.name, else: "No Role" %></td>
                <td>
                  <span class={if user.is_active, do: "badge badge-success", else: "badge badge-error"}>
                    <%= if user.is_active, do: "Active", else: "Inactive" %>
                  </span>
                </td>
                <td>
                  <.link href={~p"/admin/users/#{user.id}/edit"} class="btn btn-sm btn-outline border-base-content">
                    <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z"></path>
                    </svg>
                    Edit
                  </.link>
                  <button
                    phx-click="delete"
                    phx-value-id={user.id}
                    phx-value-type="user"
                    class="btn btn-sm btn-error"
                    data-confirm="Are you sure?"
                  >
                    <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16"></path>
                    </svg>
                    Delete
                  </button>
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>
    </div>
    """
  end

  defp render_ai_apis_table(assigns) do
    ~H"""
    <div class="card bg-base-200 shadow-xl">
      <div class="card-body">
        <h2 class="card-title">AI APIs</h2>
        <div class="overflow-x-auto">
          <table class="table table-zebra w-full">
            <thead>
              <tr>
                <th>Name</th>
                <th>Provider</th>
                <th>Model</th>
                <th>Default</th>
                <th>Actions</th>
              </tr>
            </thead>
            <tbody>
              <tr :for={api <- @ai_apis} id={"ai_api-#{api.id}"}>
                <td><%= api.name %></td>
                <td><%= api.provider %></td>
                <td><%= api.model_name %></td>
                <td>
                  <span class={if api.is_default, do: "badge badge-primary", else: "badge badge-ghost"}>
                    <%= if api.is_default, do: "Default", else: "" %>
                  </span>
                </td>
                <td>
                  <.link href={~p"/admin/ai-apis/#{api.id}/edit"} class="btn btn-sm btn-outline border-base-content">
                    <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z"></path>
                    </svg>
                    Edit
                  </.link>
                  <button
                    phx-click="delete"
                    phx-value-id={api.id}
                    phx-value-type="ai_api"
                    class="btn btn-sm btn-error"
                    data-confirm="Are you sure?"
                  >
                    <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16"></path>
                    </svg>
                    Delete
                  </button>
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>
    </div>
    """
  end


  defp render_departments_table(assigns) do
    ~H"""
    <div class="card bg-base-200 shadow-xl">
      <div class="card-body">
        <h2 class="card-title">Departments</h2>
        <div class="overflow-x-auto">
          <table class="table table-zebra w-full">
            <thead>
              <tr>
                <th>Name</th>
                <th>Description</th>
                <th>Parent</th>
                <th>API Access</th>
                <th>Status</th>
                <th>Actions</th>
              </tr>
            </thead>
            <tbody>
              <tr :for={dept <- @departments} id={"department-#{dept.id}"}>
                <td><%= dept.name %></td>
                <td><%= dept.description %></td>
                <td><%= if dept.parent, do: dept.parent.name, else: "No Parent" %></td>
                <td>
                  <span class={if dept.api_access_enabled, do: "badge badge-success", else: "badge badge-ghost"}>
                    <%= if dept.api_access_enabled, do: "Enabled", else: "Disabled" %>
                  </span>
                </td>
                <td>
                  <span class={if dept.is_active, do: "badge badge-success", else: "badge badge-error"}>
                    <%= if dept.is_active, do: "Active", else: "Inactive" %>
                  </span>
                </td>
                <td>
                  <.link href={~p"/admin/departments/#{dept.id}/edit"} class="btn btn-sm btn-outline border-base-content">
                    <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z"></path>
                    </svg>
                    Edit
                  </.link>
                  <button phx-click="delete" phx-value-id={dept.id} phx-value-type="department" class="btn btn-sm btn-error">
                    <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16"></path>
                    </svg>
                    Delete
                  </button>
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>
    </div>
    """
  end

  defp render_roles_table(assigns) do
    ~H"""
    <div class="card bg-base-200 shadow-xl">
      <div class="card-body">
        <h2 class="card-title">Roles</h2>
        <div class="overflow-x-auto">
          <table class="table table-zebra w-full">
            <thead>
              <tr>
                <th>Name</th>
                <th>Description</th>
                <th>Status</th>
                <th>Actions</th>
              </tr>
            </thead>
            <tbody>
              <tr :for={role <- @roles} id={"role-#{role.id}"}>
                <td><%= role.name %></td>
                <td><%= role.description %></td>
                <td>
                  <span class={if role.is_active, do: "badge badge-success", else: "badge badge-error"}>
                    <%= if role.is_active, do: "Active", else: "Inactive" %>
                  </span>
                </td>
                <td>
                  <.link href={~p"/admin/roles/#{role.id}/edit"} class="btn btn-sm btn-outline border-base-content">
                    <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z"></path>
                    </svg>
                    Edit
                  </.link>
                  <button phx-click="delete" phx-value-id={role.id} phx-value-type="role" class="btn btn-sm btn-error">
                    <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16"></path>
                    </svg>
                    Delete
                  </button>
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>
    </div>
    """
  end

  defp render_prompts_table(assigns) do
    ~H"""
    <div class="card bg-base-200 shadow-xl">
      <div class="card-body">
        <h2 class="card-title">Prompts</h2>
        <div class="overflow-x-auto">
          <table class="table table-zebra w-full">
            <thead>
              <tr>
                <th>Title</th>
                <th>Content</th>
                <th class="min-w-40">Departments</th>
                <th class="min-w-40">Roles</th>
                <th>Status</th>
                <th>Actions</th>
              </tr>
            </thead>
            <tbody>
              <tr :for={prompt <- @prompts} id={"prompt-#{prompt.id}"}>
                <td><%= prompt.title %></td>
                <td><%= String.slice(prompt.content, 0, 50) %>...</td>
                <td class="min-w-40">
                  <%= if prompt.department_ids && length(prompt.department_ids) > 0 do %>
                    <div class="flex flex-wrap gap-1">
                      <span :for={dept_id <- prompt.department_ids} class="badge badge-outline px-3 py-1.5 whitespace-nowrap" style="box-sizing: content-box;">
                        <%= get_department_name(dept_id, @departments) %>
                      </span>
                    </div>
                  <% else %>
                    <span class="badge badge-ghost whitespace-nowrap">All Departments</span>
                  <% end %>
                </td>
                <td class="min-w-40">
                  <%= if prompt.role_ids && length(prompt.role_ids) > 0 do %>
                    <div class="flex flex-wrap gap-1">
                      <span :for={role_id <- prompt.role_ids} class="badge badge-outline px-3 py-1.5 whitespace-nowrap" style="box-sizing: content-box;">
                        <%= get_role_name(role_id, @roles) %>
                      </span>
                    </div>
                  <% else %>
                    <span class="badge badge-ghost whitespace-nowrap">All Roles</span>
                  <% end %>
                </td>
                <td>
                  <span class={if prompt.is_active, do: "badge badge-success", else: "badge badge-error"}>
                    <%= if prompt.is_active, do: "Active", else: "Inactive" %>
                  </span>
                </td>
                <td>
                  <div class="flex gap-2">
                    <.link href={~p"/admin/prompts/#{prompt.id}/edit"} class="btn btn-sm btn-outline border-base-content">
                      <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z"></path>
                      </svg>
                      Edit
                    </.link>
                    <button phx-click="delete" phx-value-id={prompt.id} phx-value-type="prompt" class="btn btn-sm btn-error">
                      <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16"></path>
                      </svg>
                      Delete
                    </button>
                  </div>
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>
    </div>
    """
  end

  defp render_knowledge_bases_table(assigns) do
    ~H"""
    <div class="card bg-base-200 shadow-xl">
      <div class="card-body">
        <h2 class="card-title">Knowledge Bases</h2>
        <div class="overflow-x-auto">
          <table class="table table-zebra w-full">
            <thead>
              <tr>
                <th>Name</th>
                <th>Description</th>
                <th>Departments</th>
                <th>Roles</th>
                <th>Chunk Size</th>
                <th>Status</th>
                <th>Actions</th>
              </tr>
            </thead>
            <tbody>
              <tr :for={kb <- @knowledge_bases} id={"knowledge-base-#{kb.id}"}>
                <td><%= kb.name %></td>
                <td><%= kb.description %></td>
                <td>
                  <%= if kb.department_ids && length(kb.department_ids) > 0 do %>
                    <div class="flex flex-wrap gap-1">
                      <span :for={dept_id <- kb.department_ids} class="badge badge-outline">
                        <%= get_department_name(dept_id, @departments) %>
                      </span>
                    </div>
                  <% else %>
                    <span class="badge badge-ghost">All Departments</span>
                  <% end %>
                </td>
                <td>
                  <%= if kb.role_ids && length(kb.role_ids) > 0 do %>
                    <div class="flex flex-wrap gap-1">
                      <span :for={role_id <- kb.role_ids} class="badge badge-outline">
                        <%= get_role_name(role_id, @roles) %>
                      </span>
                    </div>
                  <% else %>
                    <span class="badge badge-ghost">All Roles</span>
                  <% end %>
                </td>
                <td><%= kb.chunk_size %></td>
                <td>
                  <span class={if kb.is_active, do: "badge badge-success", else: "badge badge-error"}>
                    <%= if kb.is_active, do: "Active", else: "Inactive" %>
                  </span>
                </td>
                <td>
                  <.link href={~p"/admin/knowledge-bases/#{kb.id}/edit"} class="btn btn-sm btn-outline border-base-content">
                    <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z"></path>
                    </svg>
                    Edit
                  </.link>
                  <button phx-click="delete" phx-value-id={kb.id} phx-value-type="knowledge_base" class="btn btn-sm btn-error">
                    <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16"></path>
                    </svg>
                    Delete
                  </button>
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>
    </div>
    """
  end

  defp get_department_name(dept_id, departments) do
    case Enum.find(departments, &(&1.id == dept_id)) do
      nil -> "Unknown"
      dept -> dept.name
    end
  end

  defp get_role_name(role_id, roles) do
    case Enum.find(roles, &(&1.id == role_id)) do
      nil -> "Unknown"
      role -> role.name
    end
  end
end
