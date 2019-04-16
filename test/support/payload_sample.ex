defmodule ElenchosExWeb.PayloadSample do

  def closed_a_pr, do: load("test/support/github/closed_a_pr.json")
  def create_a_pr, do: load("test/support/github/create_a_pr.json")
  def push_to_initial_branch, do: load("test/support/github/push_to_initial_branch.json")
  def push_to_master, do: load("test/support/github/push_to_master.json")
  def reopen_a_pr, do: load("test/support/github/reopen_a_pr.json")
  def update_to_branch, do: load("test/support/github/update_to_branch.json")

  def load(filename) do
    File.read!(filename)
    |> Jason.decode!()
  end
end
