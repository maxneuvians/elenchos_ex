defmodule ElenchosExWeb.PayloadController do
  use ElenchosExWeb, :controller
  require Logger

  def index(conn, payload) do
    # Determin if the payload is a push or PR
    case payload do
      %{"ref" => "refs/heads/master"} ->
        Logger.info "Push to master"
        text conn, "Ignoring push to master"

      %{"ref" => ref, "commits" => _commits, "before" => "000" <> _rest, "after" => sha} ->
        Logger.info "Inital Push to branch for #{ref}:#{sha}"
        %ElenchosEx.Release.Model{ref: ref, sha: sha}
        |> ElenchosEx.Release.save()
        text conn, "Initial Push"

      %{"ref" => ref, "commits" => _commits, "after" => sha} ->
        Logger.info "Push to branch for #{ref}:#{sha}"

        case ElenchosEx.DeploymentSupervisor.get_deployment(ref) do
          {:error, _} -> Logger.info "Received update for #{ref}, but not yet started"
          pid ->
            ElenchosEx.Deployment.update(pid, %{ref: ref, sha: sha})
            ElenchosEx.Deployment.reset(pid)
        end

        text conn, "Push"

      %{"pull_request" => %{"head" => %{"ref" => ref}}, "action" => "opened"} ->
        ref = "refs/heads/#{ref}"
        Logger.info "PR opened for #{ref}"
        ElenchosEx.DeploymentSupervisor.add_deployment(ref)
        text conn, "PR open"

      %{"pull_request" => %{"head" => %{"ref" => ref}}, "action" => "closed"} ->
        ref = "refs/heads/#{ref}"
        Logger.info "PR closed for #{ref}"
        case ElenchosEx.DeploymentSupervisor.get_deployment(ref) do
          {:error, _} -> Logger.info "Received terminate for #{ref}, but not started"
          pid -> ElenchosEx.DeploymentSupervisor.remove_deployment(pid)
        end
        text conn, "PR closed"

      %{"pull_request" =>%{"head" => %{"ref" => ref}}, "action" => "reopened"} ->
        ref = "refs/heads/#{ref}"
        Logger.info "PR repoened for #{ref}"
        ElenchosEx.DeploymentSupervisor.add_deployment(ref)
        text conn, "PR repoened"

      _ ->
        text conn, "No action taken"
    end
  end
end
