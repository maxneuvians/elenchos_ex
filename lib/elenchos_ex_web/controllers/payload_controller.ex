defmodule ElenchosExWeb.PayloadController do
  use ElenchosExWeb, :controller

  def index(conn, payload) do
    # Determin if the payload is a push or PR
    case payload do
      %{"ref" => "refs/heads/master"} ->
        # Push to master
        text conn, "Ignoring push to master"
      %{"ref" => _ref, "commits" => _commits, "before" => "000" <> _rest} ->
        # Inital Push to branch
        text conn, "Initial Push"
      %{"ref" => _ref, "commits" => _commits} ->
        # Push to branch
        text conn, "Push"
      %{"pull_request" => pr, "action" => "opened"} ->
        # Handle PR open
        text conn, "PR open"
      %{"pull_request" => pr, "action" => "closed"} ->
        # Handle PR closed
        text conn, "PR closed"
      %{"pull_request" => pr, "action" => "reopened"} ->
        # Handle PR reopen
        text conn, "PR repoened"
      _ ->
        text conn, "No action taken"
    end
  end
end
