defmodule ExcisionWeb.ClassifierController do
  use ExcisionWeb, :controller
  use OpenApiSpex.ControllerSpecs

  alias Excision.Excisions
  alias Excision.Excisions.Classifier

  action_fallback ExcisionWeb.FallbackController

  tags ["classifiers"]

  operation :index,
    summary: "List classifiers",
    description: "List all classifiers"

  def index(conn, _params) do
    classifiers = Excisions.list_classifiers()
    render(conn, :index, classifiers: classifiers)
  end

  operation :create,
    summary: "Create classifier",
    description: "Create a new classifier"

  def create(conn, %{"classifier" => classifier_params}) do
    with {:ok, %Classifier{} = classifier} <- Excisions.create_classifier(classifier_params) do
      conn
      |> put_status(:created)
      |> put_resp_header(
        "location",
        ~p"/api/decision_sites/#{classifier.decision_site_id}/classifiers/#{classifier}"
      )
      |> render(:show, classifier: classifier)
    end
  end

  operation :show,
    summary: "Show classifier",
    description: "Show a classifier"

  def show(conn, %{"id" => id}) do
    classifier = Excisions.get_classifier!(id)
    render(conn, :show, classifier: classifier)
  end

  operation :update,
    summary: "Update classifier",
    description: "Update a classifier"

  def update(conn, %{"id" => id, "classifier" => classifier_params}) do
    classifier = Excisions.get_classifier!(id)

    with {:ok, %Classifier{} = classifier} <-
           Excisions.update_classifier(classifier, classifier_params) do
      render(conn, :show, classifier: classifier)
    end
  end

  operation :delete,
    summary: "Delete classifier",
    description: "Delete a classifier"

  def delete(conn, %{"id" => id}) do
    classifier = Excisions.get_classifier!(id)

    with {:ok, %Classifier{}} <- Excisions.delete_classifier(classifier) do
      send_resp(conn, :no_content, "")
    end
  end
end
