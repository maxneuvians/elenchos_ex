defmodule ElenchosEx.Deployment do
  use GenServer
  require Logger
  alias ElenchosEx.Release

  def init(name) do
    case Release.load(name) do
      {:ok, release} -> {:ok, release}
      {:error, "Could not find release"} -> {:stop, "Could not find release"}
    end
  end

  def start_link(deployment_name) do
    Logger.info "Starting deployment for #{deployment_name}"
    GenServer.start_link(
      __MODULE__,
      deployment_name,
      name: {:global, "deployment:#{deployment_name}"}
    )
  end

  # Public API
  def get(pid) do
    {:ok, release} = GenServer.call(pid, :get)
    release
  end

  def update(pid, release) do
    GenServer.cast(pid, {:update, release})
  end

  # Private API
  def handle_call(:get, _from, state) do
    {:reply, {:ok, state}, state}
  end

  def handle_cast({:update, release}, _state) do
    {:noreply, release}
  end

  @doc """
  When the server terminates save the state
  """
  def terminate(_reason, state) do
    Logger.info "Terminating deployment for #{state.ref}"
    Release.save(state)
  end
end
