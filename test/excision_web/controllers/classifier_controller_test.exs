defmodule ExcisionWeb.ClassifierControllerTest do
  use ExcisionWeb.ConnCase

  import Excision.ExcisionsFixtures

  alias Excision.Excisions.Classifier

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
    setup [:create_decision_site]

    test "lists all classifiers", %{conn: conn, decision_site: decision_site} do
      conn = get(conn, ~p"/api/decision_sites/#{decision_site}/classifiers")

      assert json_response(conn, 200)["data"] == [
               %{
                 "id" => 1,
                 "name" => "baseline"
               }
             ]
    end
  end

  describe "create classifier" do
    setup [:create_decision_site]

    test "renders classifier when data is valid", %{conn: conn, decision_site: decision_site} do
      conn =
        post(conn, ~p"/api/decision_sites/#{decision_site}/classifiers",
          classifier: @create_attrs |> Enum.into(%{decision_site_id: decision_site.id})
        )

      assert %{"id" => id} = json_response(conn, 201)["data"]

      conn = get(conn, ~p"/api/decision_sites/#{decision_site}/classifiers/#{id}")

      assert %{
               "id" => ^id,
               "name" => "some name"
             } = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{conn: conn, decision_site: decision_site} do
      conn =
        post(conn, ~p"/api/decision_sites/#{decision_site}/classifiers",
          classifier: @invalid_attrs
        )

      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "update classifier" do
    setup [:create_decision_site, :create_classifier]

    test "renders classifier when data is valid", %{
      conn: conn,
      classifier: %Classifier{id: id} = classifier
    } do
      conn =
        put(
          conn,
          ~p"/api/decision_sites/#{classifier.decision_site_id}/classifiers/#{classifier}",
          classifier: @update_attrs
        )

      assert %{"id" => ^id} = json_response(conn, 200)["data"]

      conn = get(conn, ~p"/api/decision_sites/#{classifier.decision_site_id}/classifiers/#{id}")

      assert %{
               "id" => ^id,
               "name" => "some updated name"
             } = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{conn: conn, classifier: classifier} do
      conn =
        put(
          conn,
          ~p"/api/decision_sites/#{classifier.decision_site_id}/classifiers/#{classifier}",
          classifier: @invalid_attrs
        )

      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "delete classifier" do
    setup [:create_decision_site, :create_classifier]

    test "deletes chosen classifier", %{conn: conn, classifier: classifier} do
      conn =
        delete(
          conn,
          ~p"/api/decision_sites/#{classifier.decision_site_id}/classifiers/#{classifier}"
        )

      assert response(conn, 204)

      assert_error_sent 404, fn ->
        get(
          conn,
          ~p"/api/decision_sites/#{classifier.decision_site_id}/classifiers/#{classifier}"
        )
      end
    end
  end

  defp create_decision_site(_) do
    decision_site = decision_site_fixture()
    %{decision_site: decision_site}
  end

  defp create_classifier(%{decision_site: decision_site}) do
    classifier =
      classifier_fixture(%{
        decision_site_id: decision_site.id
      })

    %{classifier: classifier}
  end
end
