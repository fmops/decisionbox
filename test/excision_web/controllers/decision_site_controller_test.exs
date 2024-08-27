defmodule ExcisionWeb.DecisionSiteControllerTest do
  use ExcisionWeb.ConnCase, async: true

  import Excision.ExcisionsFixtures

  alias Excision.Excisions.DecisionSite

  @create_attrs %{
    name: "some name"
  }
  @update_attrs %{
    name: "some updated name"
  }
  @invalid_attrs %{name: nil}

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "index" do
    test "lists all decision_sites", %{conn: conn} do
      conn = get(conn, ~p"/api/decision_sites")
      assert json_response(conn, 200)["data"] == []
    end
  end

  describe "create decision_site" do
    test "renders decision_site when data is valid", %{conn: conn} do
      conn = post(conn, ~p"/api/decision_sites", decision_site: @create_attrs)
      assert %{"id" => id} = json_response(conn, 201)["data"]

      conn = get(conn, ~p"/api/decision_sites/#{id}")

      assert %{
               "id" => ^id,
               "name" => "some name"
             } = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, ~p"/api/decision_sites", decision_site: @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "update decision_site" do
    setup [:create_decision_site]

    test "renders decision_site when data is valid", %{
      conn: conn,
      decision_site: %DecisionSite{id: id} = decision_site
    } do
      conn = put(conn, ~p"/api/decision_sites/#{decision_site}", decision_site: @update_attrs)
      assert %{"id" => ^id} = json_response(conn, 200)["data"]

      conn = get(conn, ~p"/api/decision_sites/#{id}")

      assert %{
               "id" => ^id,
               "name" => "some updated name"
             } = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{conn: conn, decision_site: decision_site} do
      conn = put(conn, ~p"/api/decision_sites/#{decision_site}", decision_site: @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "delete decision_site" do
    setup [:create_decision_site]

    test "deletes chosen decision_site", %{conn: conn, decision_site: decision_site} do
      conn = delete(conn, ~p"/api/decision_sites/#{decision_site}")
      assert response(conn, 204)

      assert_error_sent 404, fn ->
        get(conn, ~p"/api/decision_sites/#{decision_site}")
      end
    end
  end

  describe "invoke decision_site" do
    setup [:create_decision_site]

    setup do
      bypass = Bypass.open(port: 4001)
      {:ok, bypass: bypass}
    end

    test "creates a decision with the prediction from upstream", %{
      conn: conn,
      decision_site: decision_site,
      bypass: bypass
    } do
      Bypass.expect_once(bypass, "POST", "/v1/chat/completions", fn conn ->
        Plug.Conn.resp(
          conn,
          200,
          "{\"choices\": [{\"message\": {\"content\": \"{\\\"value\\\":false}\"}}]}"
        )
      end)

      messages = [%{role: "user", content: "some message"}]

      conn =
        conn
        |> assign(
          :raw_body,
          Jason.encode!(%{
            messages: messages,
            model: ""
          })
        )
        |> Plug.Conn.put_req_header("authorization", "Bearer foo")
        |> post(~p"/api/decision_sites/#{decision_site}/invoke")

      assert response(conn, 200)

      decisions = Excision.Excisions.list_decisions_for_site(decision_site)
      assert Enum.count(decisions) == 1

      decision = Enum.at(decisions, 0)
      assert %Excision.Excisions.Decision{prediction: false} = decision
      assert Jason.decode!(decision.input) == Jason.decode!(Jason.encode!(messages))
    end
  end

  defp create_decision_site(_) do
    decision_site = decision_site_fixture()
    %{decision_site: decision_site}
  end
end
