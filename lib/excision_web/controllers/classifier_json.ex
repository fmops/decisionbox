defmodule ExcisionWeb.ClassifierJSON do
  alias Excision.Excisions.Classifier

  @doc """
  Renders a list of classifiers.
  """
  def index(%{classifiers: classifiers}) do
    %{data: for(classifier <- classifiers, do: data(classifier))}
  end

  @doc """
  Renders a single classifier.
  """
  def show(%{classifier: classifier}) do
    %{data: data(classifier)}
  end

  defp data(%Classifier{} = classifier) do
    %{
      id: classifier.id,
      name: classifier.name
    }
  end
end
