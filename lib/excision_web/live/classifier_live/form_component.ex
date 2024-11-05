defmodule ExcisionWeb.ClassifierLive.FormComponent do
  use ExcisionWeb, :live_component

  alias Excision.Excisions

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        <%= @title %>
        <:subtitle>
          In machine learning, a classifier is an algorithm that automatically assigns data into different categories or classes. It's like a sorting machine that learns from examples to make predictions about new, unseen data.  A classifier might constrain output choices such as "yes" or "no" or have several options.
        </:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="classifier-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:name]} type="text" label="Name" />
        <.input field={@form[:base_model_name]} type="text" label="Base model name" />
        <fieldset :if={@action == :new}>
          <legend class="text-md font-semibold text-zinc-800">
            Training Parameters
            <ExcisionWeb.Components.TooltipComponent.tooltip>
              <div>
                <h3 class="font-bold mb-1">Epochs</h3>
                <p class="text-white/75">
                  An epoch is one complete pass through the entire training dataset during the learning process of a machine learning model.
                </p>
              </div>

              <div>
                <h3 class="font-bold mb-1">Learning Rate</h3>
                <p class="text-white/75">
                  The learning rate controls how much the model's parameters are adjusted in response to the estimated error each time the model weights are updated.
                </p>
              </div>

              <div>
                <h3 class="font-bold mb-1">Batch Size</h3>
                <p class="text-white/75">
                  The batch size determines the number of training samples that are processed together before the model's internal parameters are updated.
                </p>
              </div>

              <div>
                <h3 class="font-bold mb-1">Sequence Length</h3>
                <p class="text-white/75">
                  Sequence length typically refers to the number of data points or time steps in a sequence, such as in time series data or natural language processing, that are considered by the model at once.
                </p>
              </div>
            </ExcisionWeb.Components.TooltipComponent.tooltip>
          </legend>
          <.inputs_for :let={fp} field={@form[:training_parameters]}>
            <.input field={fp[:epochs]} type="number" label="# Epochs" />
            <.input field={fp[:learning_rate]} type="number" label="Learning Rate" />
            <.input field={fp[:batch_size]} type="number" label="Batch Size" />
            <.input field={fp[:sequence_length]} type="number" label="Sequence Length" />
          </.inputs_for>
        </fieldset>
        <:actions>
          <.button phx-disable-with="Saving...">Save Classifier</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{classifier: classifier, action: action} = assigns, socket) do
    form =
      if action == :new do
        to_form(
          Excisions.change_classifier(classifier, %{
            base_model_name: "distilbert/distilbert-base-uncased",
            training_parameters: %{
              epochs: 3,
              learning_rate: 5.0e-3,
              batch_size: 64,
              sequence_length: 64
            }
          })
        )
      else
        to_form(Excisions.change_classifier(classifier))
      end

    {:ok,
     socket
     |> assign(assigns)
     |> assign_new(:form, fn -> form end)}
  end

  @impl true
  def handle_event("validate", %{"classifier" => classifier_params}, socket) do
    changeset =
      Excisions.change_classifier(
        socket.assigns.classifier,
        classifier_params
        |> add_decision_site_id(socket.assigns.decision_site_id)
      )

    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"classifier" => classifier_params}, socket) do
    save_classifier(
      socket,
      socket.assigns.action,
      classifier_params |> add_decision_site_id(socket.assigns.decision_site_id)
    )
  end

  defp save_classifier(socket, :edit, classifier_params) do
    case Excisions.update_classifier(socket.assigns.classifier, classifier_params) do
      {:ok, classifier} ->
        notify_parent({:saved, classifier})

        {:noreply,
         socket
         |> put_flash(:info, "Classifier updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_classifier(socket, :new, classifier_params) do
    case Excisions.create_classifier(classifier_params) do
      {:ok, classifier} ->
        notify_parent({:saved, classifier})

        {:noreply,
         socket
         |> put_flash(:info, "Classifier created successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})

  defp add_decision_site_id(params, decision_site_id) do
    Map.put(params, "decision_site_id", decision_site_id)
  end
end
