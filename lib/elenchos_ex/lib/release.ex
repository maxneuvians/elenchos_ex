defmodule ElenchosEx.Release.Model do
  defstruct [:cluster_id, :cluster_state, :deployment_state, :full_name, :ip, :polling_counter, :pr_state, :ref, :sha]
end


defmodule ElenchosEx.Release do
  @doc """
  Loads a release from the database
  """
  def load(ref) do
    case :ets.lookup(:releases, ref) do
      [{^ref, release}] -> {:ok, release}
      _ -> {:error, "Could not find release"}
    end
  end

  @doc """
  Saves a release to the database
  """
  def save(release) do
    case :ets.insert(:releases, {release.ref, release}) do
      true -> release
      _ -> {:error, "Could not save release"}
    end
  end
end
