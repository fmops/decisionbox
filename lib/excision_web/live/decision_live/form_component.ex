defmodule ExcisionWeb.DecisionLive.FormComponent do
  use ExcisionWeb, :live_component

  alias Excision.Excisions

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        <%= @title %>
        <:subtitle>Use this form to manage decision records in your database.</:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="decision-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:input]} type="text" label="Input" />
        <.input field={@form[:prediction]} type="checkbox" label="Prediction" />
        <.input field={@form[:label]} type="text" label="Label" />
        <:actions>
          <.button phx-disable-with="Saving...">Save Decision</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{decision: decision} = assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign_new(:form, fn ->
       to_form(Excisions.change_decision(decision))
     end)}
  end

  @impl true
  def handle_event("validate", %{"decision" => decision_params}, socket) do
    changeset = Excisions.change_decision(socket.assigns.decision, decision_params)
    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"decision" => decision_params}, socket) do
    save_decision(socket, socket.assigns.action, decision_params)
  end

  defp save_decision(socket, :edit, decision_params) do
    case Excisions.update_decision(socket.assigns.decision, decision_params) do
      {:ok, decision} ->
        notify_parent({:saved, decision})

        {:noreply,
         socket
         |> put_flash(:info, "Decision updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_decision(socket, :new, decision_params) do
    case Excisions.create_decision(decision_params) do
      {:ok, decision} ->
        notify_parent({:saved, decision})

        {:noreply,
         socket
         |> put_flash(:info, "Decision created successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
