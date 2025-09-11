defmodule AiChatWeb.Behaviours.AdminCrud do
  @moduledoc """
  Behaviour for admin CRUD operations to reduce code duplication.
  """

  @callback list_resources() :: list()
  @callback get_resource!(id :: any()) :: struct()
  @callback change_resource(resource :: struct()) :: Ecto.Changeset.t()
  @callback create_resource(attrs :: map()) :: {:ok, struct()} | {:error, Ecto.Changeset.t()}
  @callback update_resource(resource :: struct(), attrs :: map()) :: {:ok, struct()} | {:error, Ecto.Changeset.t()}
  @callback delete_resource(resource :: struct()) :: {:ok, struct()} | {:error, Ecto.Changeset.t()}

  @doc """
  Macro to generate standard CRUD actions for admin controllers.
  """
  defmacro __using__(opts) do
    resource_name = Keyword.get(opts, :resource_name)
    context_module = Keyword.get(opts, :context_module)
    changeset_function = Keyword.get(opts, :changeset_function, :"change_#{resource_name}")
    list_function = Keyword.get(opts, :list_function, :"list_#{resource_name}s")
    get_function = Keyword.get(opts, :get_function, :"get_#{resource_name}!")
    create_function = Keyword.get(opts, :create_function, :"create_#{resource_name}")
    update_function = Keyword.get(opts, :update_function, :"update_#{resource_name}")
    delete_function = Keyword.get(opts, :delete_function, :"delete_#{resource_name}")

    singular = resource_name
    plural = :"#{resource_name}s"
    param_key = to_string(singular)

    quote do
      def unquote(:"#{plural}")(conn, _params) do
        user = conn.assigns.current_user
        resources = unquote(context_module).unquote(list_function)()
        render(conn, "#{unquote(plural)}.html", [
          current_page: unquote(plural),
          user: user
        ] |> Keyword.put(unquote(plural), resources))
      end

      def unquote(:"new_#{singular}")(conn, _params) do
        user = conn.assigns.current_user
        changeset = unquote(context_module).unquote(changeset_function)(%unquote(context_module).unquote(String.to_atom(String.capitalize(to_string(singular)))){})
        render(conn, "new_#{unquote(singular)}.html", [
          current_page: unquote(plural),
          user: user,
          changeset: changeset
        ])
      end

      def unquote(:"create_#{singular}")(conn, %{unquote(param_key) => attrs}) do
        case unquote(context_module).unquote(create_function)(attrs) do
          {:ok, _resource} ->
            conn
            |> put_flash(:info, "#{String.capitalize(to_string(unquote(singular)))} created successfully.")
            |> redirect(to: ~p"/admin/#{unquote(plural)}")
          {:error, %Ecto.Changeset{} = changeset} ->
            render(conn, "new_#{unquote(singular)}.html", [
              current_page: unquote(plural),
              user: conn.assigns.current_user,
              changeset: changeset
            ])
        end
      end

      def unquote(:"edit_#{singular}")(conn, %{"id" => id}) do
        user = conn.assigns.current_user
        resource = unquote(context_module).unquote(get_function)(id)
        changeset = unquote(context_module).unquote(changeset_function)(resource)
        render(conn, "edit_#{unquote(singular)}.html", [
          current_page: unquote(plural),
          user: user,
          changeset: changeset
        ] |> Keyword.put(unquote(singular), resource))
      end

      def unquote(:"update_#{singular}")(conn, %{"id" => id, unquote(param_key) => attrs}) do
        resource = unquote(context_module).unquote(get_function)(id)

        case unquote(context_module).unquote(update_function)(resource, attrs) do
          {:ok, _resource} ->
            conn
            |> put_flash(:info, "#{String.capitalize(to_string(unquote(singular)))} updated successfully.")
            |> redirect(to: ~p"/admin/#{unquote(plural)}")
          {:error, %Ecto.Changeset{} = changeset} ->
            render(conn, "edit_#{unquote(singular)}.html", [
              current_page: unquote(plural),
              user: conn.assigns.current_user,
              changeset: changeset
            ] |> Keyword.put(unquote(singular), resource))
        end
      end

      def unquote(:"delete_#{singular}")(conn, %{"id" => id}) do
        resource = unquote(context_module).unquote(get_function)(id)

        case unquote(context_module).unquote(delete_function)(resource) do
          {:ok, _resource} ->
            conn
            |> put_flash(:info, "#{String.capitalize(to_string(unquote(singular)))} deleted successfully.")
            |> redirect(to: ~p"/admin/#{unquote(plural)}")
          {:error, _changeset} ->
            conn
            |> put_flash(:error, "Failed to delete #{unquote(singular)}.")
            |> redirect(to: ~p"/admin/#{unquote(plural)}")
        end
      end
    end
  end
end
