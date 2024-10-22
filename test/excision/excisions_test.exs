defmodule Excision.ExcisionsTest do
  use Excision.DataCase

  alias Excision.Excisions

  describe "decision_sites" do
    alias Excision.Excisions.DecisionSite

    import Excision.ExcisionsFixtures

    @invalid_attrs %{name: nil}

    test "list_decision_sites/0 returns all decision_sites" do
      decision_site = decision_site_fixture()
      assert Excisions.list_decision_sites(preloads: [:choices, :classifiers]) == [decision_site]
    end

    test "get_decision_site!/1 returns the decision_site with given id" do
      decision_site = decision_site_fixture()

      assert Excisions.get_decision_site!(decision_site.id, preloads: [:choices, :classifiers]) ==
               decision_site
    end

    test "create_decision_site/1 with valid data creates a decision_site" do
      valid_attrs = %{name: "some name"}

      assert {:ok, %DecisionSite{} = decision_site} = Excisions.create_decision_site(valid_attrs)
      assert decision_site.name == "some name"
    end

    test "create_decision_site/1 creates a baseline classifier" do
      valid_attrs = %{name: "some name"}

      assert {:ok, %DecisionSite{} = decision_site} = Excisions.create_decision_site(valid_attrs)

      decision_site =
        decision_site
        |> Excisions.preload_decision_site_classifiers()

      assert Enum.count(decision_site.classifiers) == 1

      assert [%Excision.Excisions.Classifier{name: "baseline"}] =
               Enum.take(decision_site.classifiers, 1)
    end

    test "create_decision_site/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Excisions.create_decision_site(@invalid_attrs)
    end

    test "update_decision_site/2 with valid data updates the decision_site" do
      decision_site = decision_site_fixture()
      update_attrs = %{name: "some updated name"}

      assert {:ok, %DecisionSite{} = decision_site} =
               Excisions.update_decision_site(decision_site, update_attrs)

      assert decision_site.name == "some updated name"
    end

    test "update_decision_site/2 with invalid data returns error changeset" do
      decision_site = decision_site_fixture()

      assert {:error, %Ecto.Changeset{}} =
               Excisions.update_decision_site(decision_site, @invalid_attrs)

      assert decision_site ==
               Excisions.get_decision_site!(decision_site.id, preloads: [:classifiers, :choices])
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

  describe "decisions" do
    alias Excision.Excisions.Decision

    import Excision.ExcisionsFixtures

    @invalid_attrs %{input: nil, label: nil, prediction: nil}

    test "list_decisions/0 returns all decisions" do
      decision = decision_fixture()
      assert Excisions.list_decisions() == [decision]
    end

    test "get_decision!/1 returns the decision with given id" do
      decision = decision_fixture()
      assert Excisions.get_decision!(decision.id) == decision
    end

    test "create_decision/1 with valid data creates a decision" do
      decision_site = decision_site_fixture()

      valid_attrs = %{
        input: "some input",
        label_id: decision_site.choices |> hd() |> then(& &1.id),
        prediction_id: decision_site.choices |> hd() |> then(& &1.id),
        decision_site_id: decision_site.id
      }

      assert {:ok, %Decision{} = decision} = Excisions.create_decision(valid_attrs)
      decision = Excisions.get_decision!(decision.id, preloads: [:label, :prediction])

      assert decision.input == "some input"
      assert decision.label.name == "some choice name"
      assert decision.prediction.name == "some choice name"
    end

    test "create_decision/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Excisions.create_decision(@invalid_attrs)
    end

    test "update_decision/2 with valid data updates the decision" do
      decision = decision_fixture()

      choices =
        Excision.Excisions.get_decision_site!(decision.decision_site_id, preloads: [:choices]).choices

      update_attrs = %{input: "some updated input", label_id: choices |> hd() |> then(& &1.id)}

      assert {:ok, %Decision{} = decision} = Excisions.update_decision(decision, update_attrs)
      decision = Excisions.get_decision!(decision.id, preloads: [:label, :prediction])

      assert decision.input == "some updated input"
      assert decision.label.name == "some choice name"
      assert decision.prediction.name == "some choice name"
    end

    test "update_decision/2 with invalid data returns error changeset" do
      decision = decision_fixture()
      assert {:error, %Ecto.Changeset{}} = Excisions.update_decision(decision, @invalid_attrs)
      assert decision == Excisions.get_decision!(decision.id)
    end

    test "delete_decision/1 deletes the decision" do
      decision = decision_fixture()
      assert {:ok, %Decision{}} = Excisions.delete_decision(decision)
      assert_raise Ecto.NoResultsError, fn -> Excisions.get_decision!(decision.id) end
    end

    test "change_decision/1 returns a decision changeset" do
      decision = decision_fixture()
      assert %Ecto.Changeset{} = Excisions.change_decision(decision)
    end
  end

  describe "classifiers" do
    alias Excision.Excisions.Classifier

    import Excision.ExcisionsFixtures

    @invalid_attrs %{name: nil}

    test "list_classifiers/0 returns all classifiers" do
      classifier = classifier_fixture()
      assert Enum.find(Excisions.list_classifiers(), false, fn c -> c == classifier end)
    end

    test "get_classifier!/1 returns the classifier with given id" do
      classifier = classifier_fixture()
      assert Excisions.get_classifier!(classifier.id) == classifier
    end

    test "create_classifier/1 with valid data creates a classifier" do
      decision_site = decision_site_fixture()

      valid_attrs = %{
        name: "some name",
        decision_site_id: decision_site.id,
        training_parameters: %{
          learning_rate: 0.1,
          batch_size: 32,
          sequence_length: 100,
          epochs: 10
        }
      }

      assert {:ok, %Classifier{} = classifier} = Excisions.create_classifier(valid_attrs)
      assert classifier.name == "some name"
      assert classifier.status == :waiting
    end

    test "create_classifier/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Excisions.create_classifier(@invalid_attrs)
    end

    test "update_classifier/2 with valid data updates the classifier" do
      classifier = classifier_fixture()
      update_attrs = %{name: "some updated name"}

      assert {:ok, %Classifier{} = classifier} =
               Excisions.update_classifier(classifier, update_attrs)

      assert classifier.name == "some updated name"
    end

    test "update_classifier/2 with invalid data returns error changeset" do
      classifier = classifier_fixture()
      assert {:error, %Ecto.Changeset{}} = Excisions.update_classifier(classifier, @invalid_attrs)
      assert classifier == Excisions.get_classifier!(classifier.id)
    end

    test "delete_classifier/1 deletes the classifier" do
      classifier = classifier_fixture()
      assert {:ok, %Classifier{}} = Excisions.delete_classifier(classifier)
      assert_raise Ecto.NoResultsError, fn -> Excisions.get_classifier!(classifier.id) end
    end

    test "change_classifier/1 returns a classifier changeset" do
      classifier = classifier_fixture()
      assert %Ecto.Changeset{} = Excisions.change_classifier(classifier)
    end
  end

  describe "choices" do
    alias Excision.Excisions.Choice

    import Excision.ExcisionsFixtures

    @invalid_attrs %{name: nil}

    test "list_choices/0 returns all choices" do
      choice = choice_fixture()
      assert [_choice, _] = Excisions.list_choices()
    end

    test "get_choice!/1 returns the choice with given id" do
      choice = choice_fixture()
      assert Excisions.get_choice!(choice.id) == choice
    end

    test "create_choice/1 with valid data creates a choice" do
      valid_attrs = %{name: "some name", decision_site_id: decision_site_fixture().id}

      assert {:ok, %Choice{} = choice} = Excisions.create_choice(valid_attrs)
      assert choice.name == "some name"
    end

    test "create_choice/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Excisions.create_choice(@invalid_attrs)
    end

    test "update_choice/2 with valid data updates the choice" do
      choice = choice_fixture()
      update_attrs = %{name: "some updated name"}

      assert {:ok, %Choice{} = choice} = Excisions.update_choice(choice, update_attrs)
      assert choice.name == "some updated name"
    end

    test "update_choice/2 with invalid data returns error changeset" do
      choice = choice_fixture()
      assert {:error, %Ecto.Changeset{}} = Excisions.update_choice(choice, @invalid_attrs)
      assert choice == Excisions.get_choice!(choice.id)
    end

    test "delete_choice/1 deletes the choice" do
      choice = choice_fixture()
      assert {:ok, %Choice{}} = Excisions.delete_choice(choice)
      assert_raise Ecto.NoResultsError, fn -> Excisions.get_choice!(choice.id) end
    end

    test "change_choice/1 returns a choice changeset" do
      choice = choice_fixture()
      assert %Ecto.Changeset{} = Excisions.change_choice(choice)
    end
  end
end
