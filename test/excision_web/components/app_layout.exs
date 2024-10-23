defmodule ExcisionWeb.Components.AppLayout do
  use ExcisionWeb.ConnCase
  import Phoenix.LiveViewTest

  test "docs links to wiki", %{conn: conn} do
    {:ok, index_live, _html} =
      live(conn, ~p"/decision_sites")

    index_live |> element("a", "Docs") |> render_click()
    {path, _flash} = assert_redirect(index_live)
    assert path == "https://github.com/fmops/decisionbox/wiki"
  end
end
