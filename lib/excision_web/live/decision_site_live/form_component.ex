defmodule ExcisionWeb.DecisionSiteLive.FormComponent do
  use ExcisionWeb, :live_component

  alias Excision.Excisions

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        <%= @title %>
        <:subtitle>Use this form to manage decision_site records in your database.</:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="decision_site-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:name]} type="text" label="Name" />
        <:actions>
          <.button phx-disable-with="Saving...">Save Decision site</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{decision_site: decision_site} = assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign_new(:form, fn ->
       to_form(Excisions.change_decision_site(decision_site))
     end)}
  end

  @impl true
  def handle_event("validate", %{"decision_site" => decision_site_params}, socket) do
    changeset = Excisions.change_decision_site(socket.assigns.decision_site, decision_site_params)
    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"decision_site" => decision_site_params}, socket) do
    save_decision_site(socket, socket.assigns.action, decision_site_params)
  end

  defp save_decision_site(socket, :edit, decision_site_params) do
    case Excisions.update_decision_site(socket.assigns.decision_site, decision_site_params) do
      {:ok, decision_site} ->
        notify_parent({:saved, decision_site})

        {:noreply,
         socket
         |> put_flash(:info, "Decision site updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_decision_site(socket, :new, decision_site_params) do
    case Excisions.create_decision_site(decision_site_params) do
      {:ok, decision_site} ->
        notify_parent({:saved, decision_site})

        {:noreply,
         socket
         |> put_flash(:info, "Decision site created successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
