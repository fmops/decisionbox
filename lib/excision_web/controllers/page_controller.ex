defmodule ExcisionWeb.PageController do
  use ExcisionWeb, :controller

  def home(conn, _params) do
    # The home page is often custom made,
    # so skip the default app layout.
    # render(conn, :home, layout: false)
    redirect(conn, to: ~p"/decision_sites")
  end
end
