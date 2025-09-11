defmodule AiChatWeb.Router do
  use AiChatWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {AiChatWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug AiChatWeb.AuthPipeline
  end

  pipeline :auth do
    plug AiChatWeb.Plugs.Auth
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", AiChatWeb do
    pipe_through :browser

    get "/", PageController, :home

    # Authentication routes
    get "/login", SessionController, :new
    post "/login", SessionController, :create
    delete "/logout", SessionController, :delete

    get "/register", RegistrationController, :new
    post "/register", RegistrationController, :create
  end

  scope "/", AiChatWeb do
    pipe_through [:browser, :auth]

    get "/dashboard", PageController, :dashboard

    # Chat routes - LiveView
    live "/chat", ChatLive, :index
    live "/chat/:id", ChatLive, :show
  end

  scope "/admin", AiChatWeb do
    pipe_through [:browser, :auth]

    # LiveView routes for real-time dashboard
    live "/dashboard", AdminDashboardLive, :index

    # User management - Mixed approach
    live "/users", AdminLive, :index  # Keep list as LiveView
    get "/users/new", Admin.UserController, :new, as: :user  # Regular controller for new
    post "/users", Admin.UserController, :create
    get "/users/:id", Admin.UserController, :show
    get "/users/:id/edit", Admin.UserController, :edit  # Regular controller for edit
    put "/users/:id", Admin.UserController, :update
    delete "/users/:id", Admin.UserController, :delete

    # Other admin routes - Mixed approach
    live "/departments", AdminLive, :index  # Keep list as LiveView
    get "/departments/new", Admin.DepartmentController, :new  # Traditional controller for new
    post "/departments", Admin.DepartmentController, :create
    get "/departments/:id/edit", Admin.DepartmentController, :edit  # Traditional controller for edit
    put "/departments/:id", Admin.DepartmentController, :update

    live "/roles", AdminLive, :index  # Keep list as LiveView
    get "/roles/new", Admin.RoleController, :new  # Traditional controller for new
    post "/roles", Admin.RoleController, :create
    get "/roles/:id/edit", Admin.RoleController, :edit  # Traditional controller for edit
    put "/roles/:id", Admin.RoleController, :update

    live "/prompts", AdminLive, :index  # Keep list as LiveView
    get "/prompts/new", Admin.PromptController, :new  # Traditional controller for new
    post "/prompts", Admin.PromptController, :create
    get "/prompts/:id/edit", Admin.PromptController, :edit  # Traditional controller for edit
    put "/prompts/:id", Admin.PromptController, :update

    live "/knowledge-bases", AdminLive, :index  # Keep list as LiveView
    get "/knowledge-bases/new", Admin.KnowledgeBaseController, :new  # Traditional controller for new
    post "/knowledge-bases", Admin.KnowledgeBaseController, :create
    get "/knowledge-bases/:id/edit", Admin.KnowledgeBaseController, :edit  # Traditional controller for edit
    put "/knowledge-bases/:id", Admin.KnowledgeBaseController, :update
    live "/ai-apis", AdminLive, :index  # Keep list as LiveView
    get "/ai-apis/new", Admin.AiApiController, :new  # Traditional controller for new
    post "/ai-apis", Admin.AiApiController, :create
    get "/ai-apis/:id/edit", Admin.AiApiController, :edit  # Traditional controller for edit
    put "/ai-apis/:id", Admin.AiApiController, :update
  end

  # Other scopes may use custom stacks.
  # scope "/api", AiChatWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:ai_chat, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: AiChatWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
