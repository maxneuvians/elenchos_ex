defmodule ElenchosEx.DeploymentTest do
  use ExUnit.Case, async: true

  import ElenchosEx.Deployment
  alias ElenchosEx.{Deployment, Release, Release.Model}

  describe "start_link" do
    test "starts a new deployment process if the release exists" do
      rel = %Model{ref: "abcd"}
      Release.save(rel)
      assert {:ok, pid} = start_link("abcd")
      Process.exit(pid, :normal)
      :ets.delete(:releases, rel.ref)
    end

    test "does not start when the release does not exist" do
      Process.flag(:trap_exit, true)
      pid = spawn_link(fn -> start_link("abcd") end)
      assert_receive {:EXIT, ^pid, :normal}
    end
  end

  describe "get" do
    test "returns the state of the process" do
      rel = %Model{ref: "abcd"}
      Release.save(rel)
      {:ok, pid} = start_link("abcd")
      assert get(pid) == rel
      Process.exit(pid, :normal)
      :ets.delete(:releases, rel.ref)
    end
  end

  describe "update" do
    test "updates the state of the process" do
      rel = %Model{ref: "abcd"}
      Release.save(rel)
      {:ok, pid} = start_link("abcd")
      update(pid, %{rel | sha: "1234"})
      assert get(pid) == %{rel | sha: "1234"}
      Process.exit(pid, :normal)
      :ets.delete(:releases, rel.ref)
    end
  end
end
