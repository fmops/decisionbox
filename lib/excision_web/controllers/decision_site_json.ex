defmodule ExcisionWeb.DecisionSiteJSON do
  alias Excision.Excisions.DecisionSite

  @doc """
  Renders a list of decision_sites.
  """
  def index(%{decision_sites: decision_sites}) do
    %{data: for(decision_site <- decision_sites, do: data(decision_site))}
  end

  @doc """
  Renders a single decision_site.
  """
  def show(%{decision_site: decision_site}) do
    %{data: data(decision_site)}
  end

  defp data(%DecisionSite{} = decision_site) do
    %{
      id: decision_site.id,
      name: decision_site.name
    }
  end
end
