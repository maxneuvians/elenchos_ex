defmodule ElenchosEx.DeploymentSupervisorTest do
  use ExUnit.Case, async: true

  import ElenchosEx.DeploymentSupervisor
  alias ElenchosEx.{Deployment, Release, Release.Model}

  describe "start_link" do
    test "it boots when the application starts" do
      refute Process.whereis(ElenchosEx.DeploymentSupervisor) == nil
    end
  end

  describe "add_deployment" do
    test "it starts a deployment if the release can be found" do
      rel = %Model{ref: "abcd"}
      Release.save(rel)
      assert {:ok, pid} = add_deployment("abcd")
      remove_deployment(pid)
      :ets.delete(:releases, rel.ref)
    end

    test "it returns an error if the release does not exist" do
      assert {:error, "Could not find release"} = add_deployment("abcd")
    end
  end

  describe "get_deployment" do
    test "returns the pid of a deployment if it exists" do
      rel = %Model{ref: "abcd"}
      Release.save(rel)
      add_deployment(rel.ref)
      assert pid = get_deployment("abcd")
      assert is_pid(pid)
      remove_deployment(pid)
      :ets.delete(:releases, rel.ref)
    end

    test "it returns an error if the release does not exist" do
      assert {:error, "Deployment does not exist"} = get_deployment("abcd")
    end
  end

  describe "remove_deployment" do
    test "removes a pid from the supervision tree" do
      rel = %Model{ref: "abcd"}
      Release.save(rel)
      {:ok, pid} = add_deployment(rel.ref)
      assert remove_deployment(pid)
      :ets.delete(:releases, rel.ref)
    end

    test "saves any changes of state" do
      rel = %Model{ref: "abcd"}
      Release.save(rel)
      {:ok, pid} = add_deployment(rel.ref)
      Deployment.update(pid, %{rel | sha: "1234"})
      assert remove_deployment(pid)
      assert {:ok, %Model{ref: "abcd", sha: "1234"}}== Release.load(rel.ref)
      :ets.delete(:releases, rel.ref)
    end
  end

  describe "children" do
    test "returns a list of children associated with the supervisor" do
      assert [] = children()
      rel = %Model{ref: "abcd"}
      Release.save(rel)
      {:ok, pid} = add_deployment(rel.ref)
      assert [{:undefined, _, :worker, [ElenchosEx.Deployment]}] = children()
      remove_deployment(pid)
      :ets.delete(:releases, rel.ref)
    end
  end

  describe "count_children" do
    test "returns a count of children associated with the supervisor" do
      assert %{active: 0, specs: 0, supervisors: 0, workers: 0} = count_children()
      rel = %Model{ref: "abcd"}
      Release.save(rel)
      {:ok, pid} = add_deployment(rel.ref)
      assert %{active: 1, specs: 1, supervisors: 0, workers: 1} = count_children()
      remove_deployment(pid)
      :ets.delete(:releases, rel.ref)
    end
  end

end
