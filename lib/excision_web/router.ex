defmodule ExcisionWeb.Router do
  use ExcisionWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {ExcisionWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
    plug OpenApiSpex.Plug.PutApiSpec, module: ExcisionWeb.ApiSpec
  end

  scope "/" do
    pipe_through :browser
    get "/swaggerui", OpenApiSpex.Plug.SwaggerUI, path: "/api/openapi"

    scope "/", ExcisionWeb do
      get "/", PageController, :home

      live_session :excision do
        live "/decision_sites", DecisionSiteLive.Index, :index
        live "/decision_sites/new", DecisionSiteLive.Index, :new
        live "/decision_sites/:id/edit", DecisionSiteLive.Index, :edit

        live "/decision_sites/:id", DecisionSiteLive.Show, :show
        live "/decision_sites/:id/show/edit", DecisionSiteLive.Show, :edit

        scope "/decision_sites/:decision_site_id" do
          live "/classifiers", ClassifierLive.Index, :index
          live "/classifiers/new", ClassifierLive.Index, :new
          live "/classifiers/:id/edit", ClassifierLive.Index, :edit

          live "/classifiers/:id", ClassifierLive.Show, :show
          live "/classifiers/:id/show/edit", ClassifierLive.Show, :edit

          live "/decisions", DecisionLive.Index, :index
          live "/decisions/new", DecisionLive.Index, :new
          live "/decisions/:id/edit", DecisionLive.Index, :edit

          live "/decisions/:id", DecisionLive.Show, :show
          live "/decisions/:id/show/edit", DecisionLive.Show, :edit
        end
      end
    end
  end

  # Other scopes may use custom stacks.
  scope "/api" do
    pipe_through :api
    get "/openapi", OpenApiSpex.Plug.RenderSpec, []

    scope "/", ExcisionWeb do
      resources "/decision_sites", DecisionSiteController, except: [:new, :edit]
      post "/decision_sites/:id/invoke", DecisionSiteController, :invoke

      resources "/decision_sites/:decision_site_id/classifiers", ClassifierController,
        except: [:new, :edit]

      resources "/decision_sites/:decision_site_id/decisions", DecisionController,
        except: [:new, :edit]
    end
  end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:excision, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: ExcisionWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
