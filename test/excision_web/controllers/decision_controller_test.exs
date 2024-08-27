defmodule ExcisionWeb.DecisionControllerTest do
  use ExcisionWeb.ConnCase

  import Excision.ExcisionsFixtures

  alias Excision.Excisions.Decision

  @create_attrs %{
    input: "some input",
    label: true,
    prediction: true
  }
  @update_attrs %{
    input: "some updated input",
    label: false,
    prediction: false
  }
  @invalid_attrs %{input: nil, label: nil, prediction: nil}

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "index" do
    setup [:create_decision_site]

    test "lists all decisions", %{conn: conn, decision_site: decision_site} do
      conn = get(conn, ~p"/api/decision_sites/#{decision_site}/decisions")
      assert json_response(conn, 200)["data"] == []
    end
  end

  describe "create decision" do
    setup [:create_decision_site]

    test "renders decision when data is valid", %{conn: conn, decision_site: decision_site} do
      conn =
        post(conn, ~p"/api/decision_sites/#{decision_site}/decisions",
          decision: @create_attrs |> Enum.into(%{decision_site_id: decision_site.id})
        )

      assert %{"id" => id} = json_response(conn, 201)["data"]

      conn = get(conn, ~p"/api/decision_sites/#{decision_site}/decisions/#{id}")

      assert %{
               "id" => ^id,
               "input" => "some input",
               "label" => true,
               "prediction" => true
             } = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{conn: conn, decision_site: decision_site} do
      conn =
        post(conn, ~p"/api/decision_sites/#{decision_site}/decisions", decision: @invalid_attrs)

      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "update decision" do
    setup [:create_decision_site, :create_decision]

    test "renders decision when data is valid", %{
      conn: conn,
      decision: %Decision{id: id} = decision
    } do
      conn =
        put(conn, ~p"/api/decision_sites/#{decision.decision_site_id}/decisions/#{decision}",
          decision: @update_attrs
        )

      assert %{"id" => ^id} = json_response(conn, 200)["data"]

      conn = get(conn, ~p"/api/decision_sites/#{decision.decision_site_id}/decisions/#{id}")

      assert %{
               "id" => ^id,
               "input" => "some updated input",
               "label" => false,
               "prediction" => false
             } = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{conn: conn, decision: decision} do
      conn =
        put(conn, ~p"/api/decision_sites/#{decision.decision_site_id}/decisions/#{decision}",
          decision: @invalid_attrs
        )

      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "delete decision" do
    setup [:create_decision_site, :create_decision]

    test "deletes chosen decision", %{conn: conn, decision: decision} do
      conn =
        delete(conn, ~p"/api/decision_sites/#{decision.decision_site_id}/decisions/#{decision}")

      assert response(conn, 204)

      assert_error_sent 404, fn ->
        get(conn, ~p"/api/decision_sites/#{decision.decision_site_id}/decisions/#{decision}")
      end
    end
  end

  defp create_decision_site(_) do
    decision_site = decision_site_fixture()
    %{decision_site: decision_site}
  end

  defp create_decision(%{decision_site: decision_site}) do
    decision =
      decision_fixture(%{
        decision_site_id: decision_site.id
      })

    %{decision: decision}
  end
end
