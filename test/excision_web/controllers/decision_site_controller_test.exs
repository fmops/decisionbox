defmodule ExcisionWeb.DecisionSiteControllerTest do
  use ExcisionWeb.ConnCase

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

    test "invokes chosen decision_site", %{conn: conn, decision_site: decision_site} do
      conn = post(conn, ~p"/api/decision_sites/#{decision_site}/invoke")

      assert response(conn, 200)
    end
  end
  

  defp create_decision_site(_) do
    decision_site = decision_site_fixture()
    %{decision_site: decision_site}
  end
end
