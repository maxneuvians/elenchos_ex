defmodule ElenchosEx.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    PersistentEts.new(:foo, "releases.tab", [:named_table])

    children = [
      ElenchosExWeb.Endpoint
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
