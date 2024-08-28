defmodule ExcisionWeb.ClassifierLiveTest do
  use ExcisionWeb.ConnCase
  use Oban.Testing, repo: Excision.Repo

  import Phoenix.LiveViewTest
  import Excision.ExcisionsFixtures

  @create_attrs %{name: "some name"}
  @update_attrs %{name: "some updated name"}
  @invalid_attrs %{name: nil}

  defp create_classifier(_) do
    classifier = classifier_fixture()
    %{classifier: classifier}
  end

  describe "Index" do
    setup [:create_classifier]

    test "lists all classifiers", %{conn: conn, classifier: classifier} do
      {:ok, _index_live, html} =
        live(conn, ~p"/decision_sites/#{classifier.decision_site_id}/classifiers")

      assert html =~ "Listing Classifiers"
      assert html =~ classifier.name
    end

    test "saves new classifier", %{conn: conn} do
      decision_site = decision_site_fixture()

      {:ok, index_live, _html} = live(conn, ~p"/decision_sites/#{decision_site}/classifiers")

      assert index_live |> element("a", "New Classifier") |> render_click() =~
               "New Classifier"

      assert_patch(index_live, ~p"/decision_sites/#{decision_site}/classifiers/new")

      assert index_live
             |> form("#classifier-form", classifier: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#classifier-form", classifier: @create_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/decision_sites/#{decision_site}/classifiers")

      html = render(index_live)
      assert html =~ "Classifier created successfully"
      assert html =~ "some name"

      classifier =
        Excision.Excisions.list_classifiers()
        |> Enum.sort(&(&1.inserted_at > &2.inserted_at))
        |> hd()

      # Oban runs in-line in tests so we should be training already
      assert classifier.status == :training
    end

    test "updates classifier in listing", %{conn: conn, classifier: classifier} do
      {:ok, index_live, _html} =
        live(conn, ~p"/decision_sites/#{classifier.decision_site_id}/classifiers")

      assert index_live |> element("#classifiers-#{classifier.id} a", "Edit") |> render_click() =~
               "Edit Classifier"

      assert_patch(
        index_live,
        ~p"/decision_sites/#{classifier.decision_site_id}/classifiers/#{classifier}/edit"
      )

      assert index_live
             |> form("#classifier-form", classifier: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#classifier-form", classifier: @update_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/decision_sites/#{classifier.decision_site_id}/classifiers")

      html = render(index_live)
      assert html =~ "Classifier updated successfully"
      assert html =~ "some updated name"
    end

    test "deletes classifier in listing", %{conn: conn, classifier: classifier} do
      {:ok, index_live, _html} =
        live(conn, ~p"/decision_sites/#{classifier.decision_site_id}/classifiers")

      assert index_live |> element("#classifiers-#{classifier.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#classifiers-#{classifier.id}")
    end
  end

  describe "Show" do
    setup [:create_classifier]

    test "displays classifier", %{conn: conn, classifier: classifier} do
      {:ok, _show_live, html} =
        live(conn, ~p"/decision_sites/#{classifier.decision_site_id}/classifiers/#{classifier}")

      assert html =~ "Show Classifier"
      assert html =~ classifier.name
    end

    test "updates classifier within modal", %{conn: conn, classifier: classifier} do
      {:ok, show_live, _html} =
        live(conn, ~p"/decision_sites/#{classifier.decision_site_id}/classifiers/#{classifier}")

      assert show_live |> element("a", "Edit") |> render_click() =~
               "Edit Classifier"

      assert_patch(
        show_live,
        ~p"/decision_sites/#{classifier.decision_site_id}/classifiers/#{classifier}/show/edit"
      )

      assert show_live
             |> form("#classifier-form", classifier: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert show_live
             |> form("#classifier-form", classifier: @update_attrs)
             |> render_submit()

      assert_patch(
        show_live,
        ~p"/decision_sites/#{classifier.decision_site_id}/classifiers/#{classifier}"
      )

      html = render(show_live)
      assert html =~ "Classifier updated successfully"
      assert html =~ "some updated name"
    end
  end
end
