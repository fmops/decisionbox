defmodule ExcisionWeb.DecisionSiteLive.FormComponent do
  use ExcisionWeb, :live_component

  alias Excision.Excisions

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        <%= @title %>
        <:subtitle>
          In an LLM-based app, a "decision site" refers to a point in the application's logic where the LLM's output significantly influences the application's behavior or the user experience. It's where the LLM's capabilities are leveraged to make a choice, guide a process, or generate content that directly impacts what happens next.
        </:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="decision_site-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:name]} type="text" label="Name" />
        <fieldset>
          <legend class="text-sm font-semibold text-zinc-800">Choices</legend>
          <.inputs_for :let={fp} field={@form[:choices]}>
            <div class="flex">
              <input type="hidden" name="decision_site[choices_sort][]" value={fp.index} />
              <div class="grow">
                <.input field={fp[:name]} type="text" placeholder="Choice name" />
              </div>
              <button
                type="button"
                class="flex"
                name="decision_site[choices_drop][]"
                value={fp.index}
                phx-click={JS.dispatch("change")}
              >
                <.icon name="hero-x-mark" class="w-6 h-6 relative top-4" />
              </button>
            </div>
          </.inputs_for>
          <input type="hidden" name="decision_site[choices_drop][]" />

          <.button
            type="button"
            name="decision_site[choices_sort][]"
            value="new"
            phx-click={JS.dispatch("change")}
          >
            Add Choice
          </.button>
        </fieldset>
        <:actions>
          <.button
            phx-disable-with="Saving..."
            data-confirm="Warning: changing choices can affect the integrity of previously labelled data and trained classifiers. Consider creating a new decision site in order to avoid this issue."
          >
            Save Decision site
          </.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{decision_site: decision_site} = assigns, socket) do
    params = %{
      name: "foo",
      choices: [
        %{name: "true"},
        %{name: "false"}
      ]
    }

    {:ok,
     socket
     |> assign(assigns)
     |> assign_new(:form, fn ->
       # to_form(Excisions.change_decision_site(decision_site))
       to_form(Excisions.change_decision_site(decision_site, params))
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
        notify_parent({:saved, {:edit, decision_site}})

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
        notify_parent({:saved, {:new, decision_site}})

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
