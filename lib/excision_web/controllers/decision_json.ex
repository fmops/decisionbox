defmodule ExcisionWeb.DecisionJSON do
  alias Excision.Excisions.Decision

  @doc """
  Renders a list of decisions.
  """
  def index(%{decisions: decisions}) do
    %{data: for(decision <- decisions, do: data(decision))}
  end

  @doc """
  Renders a single decision.
  """
  def show(%{decision: decision}) do
    %{data: data(decision)}
  end

  defp data(%Decision{} = decision) do
    %{
      id: decision.id,
      input: decision.input,
      prediction: decision.prediction,
      label: decision.label
    }
  end
end
