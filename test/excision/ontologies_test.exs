defmodule Excision.OntologiesTest do
  use Excision.DataCase

  alias Excision.Ontologies

  describe "labels" do
    alias Excision.Ontologies.Label

    import Excision.ExcisionsFixtures, only: [decision_site_fixture: 0]
    import Excision.OntologiesFixtures

    @invalid_attrs %{name: nil}

    test "list_labels/0 returns all labels" do
      label = label_fixture()
      assert Ontologies.list_labels() == [label]
    end

    test "get_label!/1 returns the label with given id" do
      label = label_fixture()
      assert Ontologies.get_label!(label.id) == label
    end

    test "create_label/1 with valid data creates a label" do
      valid_attrs = %{name: "some name", decision_site_id: decision_site_fixture().id}

      assert {:ok, %Label{} = label} = Ontologies.create_label(valid_attrs)
      assert label.name == "some name"
    end

    test "create_label/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Ontologies.create_label(@invalid_attrs)
    end

    test "update_label/2 with valid data updates the label" do
      label = label_fixture()
      update_attrs = %{name: "some updated name"}

      assert {:ok, %Label{} = label} = Ontologies.update_label(label, update_attrs)
      assert label.name == "some updated name"
    end

    test "update_label/2 with invalid data returns error changeset" do
      label = label_fixture()
      assert {:error, %Ecto.Changeset{}} = Ontologies.update_label(label, @invalid_attrs)
      assert label == Ontologies.get_label!(label.id)
    end

    test "delete_label/1 deletes the label" do
      label = label_fixture()
      assert {:ok, %Label{}} = Ontologies.delete_label(label)
      assert_raise Ecto.NoResultsError, fn -> Ontologies.get_label!(label.id) end
    end

    test "change_label/1 returns a label changeset" do
      label = label_fixture()
      assert %Ecto.Changeset{} = Ontologies.change_label(label)
    end
  end
end
