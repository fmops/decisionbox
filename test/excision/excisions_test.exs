defmodule Excision.ExcisionsTest do
  use Excision.DataCase

  alias Excision.Excisions

  describe "decision_sites" do
    alias Excision.Excisions.DecisionSite

    import Excision.ExcisionsFixtures

    @invalid_attrs %{name: nil}

    test "list_decision_sites/0 returns all decision_sites" do
      decision_site = decision_site_fixture()
      assert Excisions.list_decision_sites() == [decision_site]
    end

    test "get_decision_site!/1 returns the decision_site with given id" do
      decision_site = decision_site_fixture()
      assert Excisions.get_decision_site!(decision_site.id) == decision_site
    end

    test "create_decision_site/1 with valid data creates a decision_site" do
      valid_attrs = %{name: "some name"}

      assert {:ok, %DecisionSite{} = decision_site} = Excisions.create_decision_site(valid_attrs)
      assert decision_site.name == "some name"
    end

    test "create_decision_site/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Excisions.create_decision_site(@invalid_attrs)
    end

    test "update_decision_site/2 with valid data updates the decision_site" do
      decision_site = decision_site_fixture()
      update_attrs = %{name: "some updated name"}

      assert {:ok, %DecisionSite{} = decision_site} = Excisions.update_decision_site(decision_site, update_attrs)
      assert decision_site.name == "some updated name"
    end

    test "update_decision_site/2 with invalid data returns error changeset" do
      decision_site = decision_site_fixture()
      assert {:error, %Ecto.Changeset{}} = Excisions.update_decision_site(decision_site, @invalid_attrs)
      assert decision_site == Excisions.get_decision_site!(decision_site.id)
    end

    test "delete_decision_site/1 deletes the decision_site" do
      decision_site = decision_site_fixture()
      assert {:ok, %DecisionSite{}} = Excisions.delete_decision_site(decision_site)
      assert_raise Ecto.NoResultsError, fn -> Excisions.get_decision_site!(decision_site.id) end
    end

    test "change_decision_site/1 returns a decision_site changeset" do
      decision_site = decision_site_fixture()
      assert %Ecto.Changeset{} = Excisions.change_decision_site(decision_site)
    end
  end
end
