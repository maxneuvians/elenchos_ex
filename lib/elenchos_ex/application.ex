defmodule ElenchosEx.Application do
  @moduledoc false

  use Application

  def start(_type, _args) do
    PersistentEts.new(:releases, Application.get_env(:elenchos_ex, :db, "releases.tab"), [:set, :named_table, :public])

    children = [
      ElenchosExWeb.Endpoint,
      {ElenchosEx.DeploymentSupervisor, []}
      # Starts a worker by calling: ElenchosEx.Worker.start_link(arg)
      # {ElenchosEx.Worker, arg},
    ]

    opts = [strategy: :one_for_one, name: ElenchosEx.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    ElenchosExWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
