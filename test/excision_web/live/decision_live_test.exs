defmodule ExcisionWeb.DecisionLive do
  use ExcisionWeb.ConnCase

  import Phoenix.LiveViewTest
  import Excision.ExcisionsFixtures

  defp create_decision(_) do
    decision_site = decision_site_fixture()
    decision = decision_fixture(%{decision_site_id: decision_site.id})
    %{decision: decision}
  end

  describe "Index" do
    setup [:create_decision]

    test "lists decisions for decision_site", %{conn: conn, decision: decision} do
      {:ok, _index_live, html} =
        live(conn, ~p"/decision_sites/#{decision.decision_site_id}/decisions")

      assert html =~ "Listing Decisions for Decision Site"
      assert html =~ decision.input
    end

    test "works when there are no decisions", %{conn: conn} do
      decision_site = decision_site_fixture()

      {:ok, _index_live, html} = live(conn, ~p"/decision_sites/#{decision_site.id}/decisions")

      assert html =~ "Listing Decisions for Decision Site"
    end
  end
end
