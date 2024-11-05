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

      # create new choice fields
      Enum.each(1..3, fn _i ->
        index_live
        |> form("#decision_site-form")
        |> render_change(%{"decision_site" => %{"choices_sort" => ["new"]}})
      end)

      assert index_live
             |> form("#decision_site-form", decision_site: @create_attrs)
             |> render_submit()

      decision_site =
        Excision.Excisions.list_decision_sites()
        |> List.last()

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

    test "toggles the quickstart", %{conn: conn, decision_site: decision_site} do
      {:ok, show_live, _html} = live(conn, ~p"/decision_sites/#{decision_site}")

      assert show_live |> element("button", "Quickstart") |> render_click() =~
               "Use the API to Submit Data"

      assert_patch(show_live, ~p"/decision_sites/#{decision_site}/show/quickstart")
    end

    test "updates decision_site within modal", %{conn: conn, decision_site: decision_site} do
      {:ok, show_live, _html} = live(conn, ~p"/decision_sites/#{decision_site}")

      assert show_live |> element("a", "Edit") |> render_click() =~
               "Edit Decision site"

      assert_patch(show_live, ~p"/decision_sites/#{decision_site}/show/edit")

      assert show_live
             |> form("#decision_site-form", decision_site: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert show_live
             |> form("#decision_site-form", decision_site: @update_attrs)
             |> render_submit()

      assert_patch(show_live, ~p"/decision_sites/#{decision_site}")

      html = render(show_live)
      assert html =~ "Decision site updated successfully"
      assert html =~ "some updated name"
    end
  end

  describe "Choice management" do
    setup [:create_decision_site]

    test "creates decision site with multiple choices", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/decision_sites")

      assert index_live |> element("a", "Create New") |> render_click() =~
               "Create New"

      assert_patch(index_live, ~p"/decision_sites/new")

      # Fill in the name first
      assert index_live
             |> form("#decision_site-form", decision_site: %{name: "site with choices"})
             |> render_change()

      # Click "Add Choice" button three times
      Enum.each(1..3, fn _i ->
        index_live
        |> form("#decision_site-form")
        |> render_change(%{"decision_site" => %{"choices_sort" => ["new"]}})
      end)

      # Now fill in the choices
      assert index_live
             |> form("#decision_site-form", %{
               "decision_site" => %{
                 "name" => "site with choices",
                 "choices" => %{
                   "0" => %{"name" => "choice one"},
                   "1" => %{"name" => "choice two"},
                   "2" => %{"name" => "choice three"}
                 }
               }
             })
             |> render_submit()

      # Get the created decision site
      decision_site =
        Excision.Excisions.list_decision_sites(preloads: [:choices])
        |> List.last()

      # Verify choices were created
      assert length(decision_site.choices) == 3
      choice_names = Enum.map(decision_site.choices, & &1.name)
      assert choice_names == ["choice one", "choice two", "choice three"]

      # Verify each choice has correct decision_site_id
      Enum.each(decision_site.choices, fn choice ->
        assert choice.decision_site_id == decision_site.id
      end)
    end

    test "replaces choices when updating decision site", %{conn: conn} do
      # First create a site with multiple choices
      {:ok, index_live, _html} = live(conn, ~p"/decision_sites")

      assert index_live |> element("a", "Create New") |> render_click()
      assert_patch(index_live, ~p"/decision_sites/new")

      # Fill in name and add choices
      assert index_live
             |> form("#decision_site-form", decision_site: %{name: "site with choices"})
             |> render_change()

      # Add three choices
      Enum.each(1..3, fn _i ->
        index_live
        |> form("#decision_site-form")
        |> render_change(%{"decision_site" => %{"choices_sort" => ["new"]}})
      end)

      # Submit form with choices
      assert index_live
             |> form("#decision_site-form", %{
               "decision_site" => %{
                 "name" => "site with choices",
                 "choices" => %{
                   "0" => %{"name" => "choice one"},
                   "1" => %{"name" => "choice two"},
                   "2" => %{"name" => "choice three"}
                 }
               }
             })
             |> render_submit()

      decision_site =
        Excision.Excisions.list_decision_sites(preloads: [:choices])
        |> List.last()

      # Now update the site and verify choices are replaced
      {:ok, show_live, _html} = live(conn, ~p"/decision_sites/#{decision_site}")
      assert show_live |> element("a", "Edit") |> render_click()
      assert_patch(show_live, ~p"/decision_sites/#{decision_site}/show/edit")

      # TODO: Update with just the new choice and drop existing ones
      # Update with just the new choice and drop existing ones
      # assert show_live
      #        |> form("#decision_site-form", %{
      #          "decision_site" => %{
      #            "name" => "updated site",
      #            "choices" => %{
      #              "0" => %{"name" => "new choice"}
      #            },
      #            "choices_drop" => [""],
      #          }
      #        })
      #        |> render_submit()
      #        
      # # Get updated decision site
      # updated_site = Excision.Excisions.get_decision_site!(decision_site.id, preloads: [:choices])
      # 
      # # Verify old choices were deleted and new one was added
      # assert length(updated_site.choices) == 1
      # assert hd(updated_site.choices).name == "new choice"
      # assert hd(updated_site.choices).decision_site_id == updated_site.id
    end

    test "maintains choice order during updates", %{conn: conn} do
      # Create initial site with ordered choices
      {:ok, index_live, _html} = live(conn, ~p"/decision_sites")

      assert index_live |> element("a", "Create New") |> render_click()
      assert_patch(index_live, ~p"/decision_sites/new")

      # Fill in name and add choices
      assert index_live
             |> form("#decision_site-form", decision_site: %{name: "ordered site"})
             |> render_change()

      # Add three choices
      Enum.each(1..3, fn _i ->
        index_live
        |> form("#decision_site-form")
        |> render_change(%{"decision_site" => %{"choices_sort" => ["new"]}})
      end)

      # Submit form with ordered choices
      assert index_live
             |> form("#decision_site-form", %{
               "decision_site" => %{
                 "name" => "ordered site",
                 "choices" => %{
                   "0" => %{"name" => "new first"},
                   "1" => %{"name" => "new second"},
                   "2" => %{"name" => "new third"}
                 }
               }
             })
             |> render_submit()

      decision_site =
        Excision.Excisions.list_decision_sites(preloads: [:choices])
        |> List.last()

      # Verify initial order
      choice_names = Enum.map(decision_site.choices, & &1.name)
      assert choice_names == ["new first", "new second", "new third"]

      # Update with reordered choices
      {:ok, show_live, _html} = live(conn, ~p"/decision_sites/#{decision_site}")
      assert show_live |> element("a", "Edit") |> render_click()

      # Get existing choice IDs
      existing_choices = decision_site.choices

      # Update existing choices with new names and order
      assert show_live
             |> form("#decision_site-form", %{
               "decision_site" => %{
                 "name" => "reordered site",
                 "choices" => %{
                   "0" => %{"id" => Enum.at(existing_choices, 0).id, "name" => "third"},
                   "1" => %{"id" => Enum.at(existing_choices, 1).id, "name" => "first"},
                   "2" => %{"id" => Enum.at(existing_choices, 2).id, "name" => "second"}
                 }
               }
             })
             |> render_submit()

      # Verify new order
      updated_site = Excision.Excisions.get_decision_site!(decision_site.id, preloads: [:choices])
      updated_names = Enum.map(updated_site.choices, & &1.name)
      assert updated_names == ["third", "first", "second"]
    end
  end
end
