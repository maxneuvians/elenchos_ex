defmodule ElenchosEx.DeploymentSupervisor do
  use DynamicSupervisor

  alias ElenchosEx.{Deployment, Release}

  def start_link(_args) do
    DynamicSupervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(:ok) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  @doc """
  Start a deployment process and adds it to supervision
  """
  def add_deployment(deployment_name) do
    case DynamicSupervisor.start_child(__MODULE__, {Deployment, deployment_name}) do
      {:ok, pid} -> {:ok, pid}
      {:error, _} -> {:error, "Could not find release"}
    end
  end

  @doc """
  Get a deployment process
  """
  def get_deployment(deployment_name) do
    case :global.whereis_name("deployment:#{deployment_name}") do
      :undefined -> {:error, "Deployment does not exist"}
      pid -> pid
    end
  end

  @doc """
  Terminate a deployment process and remove it from supervision.
  Saves the state to the Release DB in advance
  """
  def remove_deployment(deployment_pid) do
    deployment_pid
    |> Deployment.get()
    |> Release.save()

    DynamicSupervisor.terminate_child(__MODULE__, deployment_pid)
  end

  @doc """
  Method to check which processes are under supervision
  """
  def children() do
    DynamicSupervisor.which_children(__MODULE__)
  end

  @doc """
  Method to check which processes are under supervision
  """
  def count_children() do
    DynamicSupervisor.count_children(__MODULE__)
  end
end
