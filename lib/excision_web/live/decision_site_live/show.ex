defmodule ExcisionWeb.DecisionSiteLive.Show do
  use ExcisionWeb, :live_view

  alias Excision.Excisions

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    decision_site =
      Excisions.get_decision_site!(id, preloads: [:active_classifier, :decisions, :classifiers])

    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:decision_site, decision_site)
     |> assign(:num_decisions, decision_site.decisions |> Enum.count())
     |> assign(
       :num_labelled_decisions,
       decision_site.decisions |> Enum.filter(&(not is_nil(&1.label))) |> Enum.count()
     )
     |> assign(:num_classifiers, decision_site.classifiers |> Enum.count())}
  end

  defp page_title(:show), do: "Show Decision site"
  defp page_title(:edit), do: "Edit Decision site"
end
