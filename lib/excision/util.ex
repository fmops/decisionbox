defmodule Excision.Util do
  @doc """
  Creates a model repository for bumblebee
  """
  def build_bumblebee_model_repository(model_name) do
    {:hf, model_name, auth_token: Application.get_env(:excision, :hugging_face_auth_token)}
  end
end
