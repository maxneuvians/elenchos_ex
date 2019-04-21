defmodule ElenchosEx.Deployment do
  use GenServer
  require Logger
  alias ElenchosEx.Release

  @message_delay 10

  def init(name) do
    case Release.load(name) do
      {:ok, release} ->
        next()
        {:ok, %{release | deployment_state: :initial}}
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

  def reset(pid) do
    Process.send(pid, :reset, [])
  end

  def update(pid, release) do
    GenServer.cast(pid, {:update, release})
  end

  # Private API
  def handle_call(:get, _from, state) do
    {:reply, {:ok, state}, state}
  end

  def handle_cast({:update, release}, state) do
    {:noreply, Map.merge(state, release)}
  end

  def handle_info(:await_deployment, state) do
    Logger.info "Awaiting cluster deployment for #{state.ref}"
    next()
    {:noreply, state}
  end

  def handle_info(:apply_configuration, state) do
    Logger.info "Applying cluster configuration for #{state.ref}"
    next()
    {:noreply, state}
  end

  def handle_info(:build_docker_files, state) do
    Logger.info "Building docker files for #{state.ref}"
    next()
    {:noreply, state}
  end

  def handle_info(:configure_kustomize, state) do
    Logger.info "Configuring kustomize for #{state.ref}"
    next()
    {:noreply, state}
  end

  def handle_info(:create_cluster, state) do
    Logger.info "Creating cluster for #{state.ref}"
    next()
    {:noreply, %{state | polling_counter: 0}}
  end

  def handle_info(:next, state) do
    case state.deployment_state do
      :applying_configuration ->
        next(:await_deployment)
        {:noreply, %{state | deployment_state: :awaiting_deployment}}

      :awaiting_deployment ->
        if state.ip do
          {:noreply, %{state | deployment_state: :deployed}}
        else
          next(:poll_loadbalancer)
          {:noreply, state}
        end

      :building_docker_files ->
        next(:configure_kustomize)
        {:noreply, %{state | deployment_state: :configuring_kustomize}}

      :configuring_kustomize ->
        next(:apply_configuration)
        {:noreply, %{state | deployment_state: :applying_configuration}}

      :creating_cluster ->
        if state.cluster_id do
          next(:build_docker_files)
          {:noreply, %{state | deployment_state: :building_docker_files}}
        else
          next(:poll_cluster)
          {:noreply, state}
        end

      :initial ->
        next(:create_cluster)
        {:noreply, %{state | deployment_state: :creating_cluster}}

      _ ->
        Logger.error "#{state.ref} is in an unkown state: #{state.deployment_state}"
        {:noreply, state}
    end
  end

  def handle_info(:poll_cluster, state) do
    Logger.info "Polling cluster for #{state.ref} (Attempt #{state.polling_counter})"
    :timer.sleep(2_000)
    next()
    {:noreply, %{state | polling_counter: state.polling_counter + 1}}
  end

  def handle_info(:poll_loadbalancer, state) do
    Logger.info "Polling loadbalancer for #{state.ref} (Attempt #{state.polling_counter})"
    :timer.sleep(2_000)
    next()
    {:noreply, %{state | polling_counter: state.polling_counter + 1}}
  end

  def handle_info(:reset, state) do
    Logger.info "Resetting deployment process for #{state.ref}"
    next()
    {:noreply, %{state | deployment_state: :initial}}
  end

  @doc """
  When the server terminates save the state
  """
  def terminate(_reason, state) do
    Logger.info "Terminating deployment for #{state.ref}"
    Release.save(state)
  end

  defp next() do
    Process.send_after(self(), :next, @message_delay)
  end

  defp next(stage) do
    Process.send_after(self(), stage, @message_delay)
  end

end
