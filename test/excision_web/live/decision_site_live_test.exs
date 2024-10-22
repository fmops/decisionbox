defmodule ExcisionWeb.DecisionSiteLiveTest do
  use ExcisionWeb.ConnCase

  import Phoenix.LiveViewTest
  import Excision.ExcisionsFixtures

  @create_attrs %{
    name: "some name",
    choices: %{
      0 => %{name: "true"},
      1 => %{name: "false"}
    }
  }
  @update_attrs %{name: "some updated name"}
  @invalid_attrs %{name: nil}

  defp create_decision_site(_) do
    decision_site = decision_site_fixture()
    %{decision_site: decision_site}
  end

  describe "Index" do
    setup [:create_decision_site]

    test "lists all decision_sites", %{conn: conn, decision_site: decision_site} do
      {:ok, _index_live, html} = live(conn, ~p"/decision_sites")

      assert html =~ "Listing Decision sites"
      assert html =~ decision_site.name
    end

    test "saves new decision_site", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/decision_sites")

      assert index_live |> element("a", "Create New") |> render_click() =~
               "Create New"

      assert_patch(index_live, ~p"/decision_sites/new")

      assert index_live
             |> form("#decision_site-form", decision_site: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#decision_site-form", decision_site: @create_attrs)
             |> render_submit()

      decision_site =
        Excision.Excisions.list_decision_sites()
        |> List.last()
        |> IO.inspect()

      assert_redirect(index_live, ~p"/decision_sites/#{decision_site}/show/quickstart")
    end

    test "updates decision_site in listing", %{conn: conn, decision_site: decision_site} do
      {:ok, index_live, _html} = live(conn, ~p"/decision_sites")

      assert index_live
             |> element("#decision_sites-#{decision_site.id} a", "Edit")
             |> render_click() =~
               "Edit decision site: #{decision_site.name}"

      assert_patch(index_live, ~p"/decision_sites/#{decision_site}/edit")

      assert index_live
             |> form("#decision_site-form", decision_site: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#decision_site-form", decision_site: @update_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/decision_sites")

      html = render(index_live)
      assert html =~ "Decision site updated successfully"
      assert html =~ "some updated name"
    end

    test "deletes decision_site in listing", %{conn: conn, decision_site: decision_site} do
      {:ok, index_live, _html} = live(conn, ~p"/decision_sites")

      assert index_live
             |> element("#decision_sites-#{decision_site.id} a", "Delete")
             |> render_click()

      refute has_element?(index_live, "#decision_sites-#{decision_site.id}")
    end
  end

  describe "Show" do
    setup [:create_decision_site]

    test "displays decision_site", %{conn: conn, decision_site: decision_site} do
      {:ok, _show_live, html} = live(conn, ~p"/decision_sites/#{decision_site}")

      assert html =~ "Show Decision site"
      assert html =~ decision_site.name

      assert html =~ "Baseline Accuracy"
    end

    # test "updates decision_site within modal", %{conn: conn, decision_site: decision_site} do
    #   {:ok, show_live, _html} = live(conn, ~p"/decision_sites/#{decision_site}")
    #
    #   assert show_live |> element("a", "Edit") |> render_click() =~
    #            "Edit Decision site"
    #
    #   assert_patch(show_live, ~p"/decision_sites/#{decision_site}/show/edit")
    #
    #   assert show_live
    #          |> form("#decision_site-form", decision_site: @invalid_attrs)
    #          |> render_change() =~ "can&#39;t be blank"
    #
    #   assert show_live
    #          |> form("#decision_site-form", decision_site: @update_attrs)
    #          |> render_submit()
    #
    #   assert_patch(show_live, ~p"/decision_sites/#{decision_site}")
    #
    #   html = render(show_live)
    #   assert html =~ "Decision site updated successfully"
    #   assert html =~ "some updated name"
    # end
  end
end
