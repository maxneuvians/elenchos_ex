defmodule ElenchosEx.DeploymentTest do
  use ExUnit.Case, async: true

  import ElenchosEx.Deployment
  alias ElenchosEx.{Release, Release.Model}

  @ref "abcd"
  @message_delay 11

  setup do
    :ets.delete(:releases, @ref)
    rel = %Model{ref: @ref}
    Release.save(rel)
    {:ok, %{rel: rel}}
  end

  describe "init" do
    test "starts a new deployment process if the release exists" do
      assert {:ok, _release} = init(@ref)
    end

    test "does not start when the release does not exist" do
      assert {:stop, "Could not find release"} = init("")
    end

    test "changes state to :initial when starting" do
      {:ok, release} = init(@ref)
      assert release.deployment_state == :initial
    end
  end

  describe "get" do
    test "returns the state of the process" do
      {:ok, pid} = start_link(@ref)
      assert get(pid).ref == @ref
      Process.exit(pid, :kill)
    end
  end

  describe "update" do
    test "updates the state of the process", %{rel: rel} do
      {:ok, pid} = start_link(@ref)
      update(pid, %{rel | sha: "1234"})
      assert get(pid) == %{rel | sha: "1234"}
      Process.exit(pid, :kill)
    end
  end

  describe "next" do

    test "changes the state from applying_configuration -> awaiting_deployment", %{rel: rel} do
      rel = %{rel | deployment_state: :applying_configuration}
      assert {:noreply, %{deployment_state: :awaiting_deployment}} = handle_info(:next, rel)
      assert_receive :await_deployment, @message_delay
    end

    test "changes the state from awaiting_deployment -> deployed if there is an IP in the release", %{rel: rel} do
      rel = %{rel | deployment_state: :awaiting_deployment, ip: :foo}
      assert {:noreply, %{deployment_state: :deployed}} = handle_info(:next, rel)
    end

    test "keeps the state awaiting_deployment if there is no IP in the release", %{rel: rel} do
      rel = %{rel | deployment_state: :awaiting_deployment}
      assert {:noreply, %{deployment_state: :awaiting_deployment}} = handle_info(:next, rel)
      assert_receive :poll_loadbalancer, @message_delay
    end

    test "changes the state from building_docker_files -> configuring_kustomize", %{rel: rel} do
      rel = %{rel | deployment_state: :building_docker_files}
      assert {:noreply, %{deployment_state: :configuring_kustomize}} = handle_info(:next, rel)
      assert_receive :configure_kustomize, @message_delay
    end

    test "changes the state from configuring_kustomize -> applying_configuration", %{rel: rel} do
      rel = %{rel | deployment_state: :configuring_kustomize}
      assert {:noreply, %{deployment_state: :applying_configuration}} = handle_info(:next, rel)
      assert_receive :apply_configuration, @message_delay
    end

    test "changes the state from creating_cluster -> building_docker_files if there is a cluster id in the release", %{rel: rel} do
      rel = %{rel | deployment_state: :creating_cluster, cluster_id: :foo}
      assert {:noreply, %{deployment_state: :building_docker_files}} = handle_info(:next, rel)
      assert_receive :build_docker_files, @message_delay
    end

    test "keeps the state creating_cluster if there is no cluster id in the release", %{rel: rel} do
      rel = %{rel | deployment_state: :creating_cluster}
      assert {:noreply, %{deployment_state: :creating_cluster}} = handle_info(:next, rel)
      assert_receive :poll_cluster, @message_delay
    end

    test "changes the state from initial -> creating_cluster", %{rel: rel} do
      rel = %{rel | deployment_state: :initial}
      assert {:noreply, %{deployment_state: :creating_cluster}} = handle_info(:next, rel)
      assert_receive :create_cluster, @message_delay
    end

    test "does not change state if the state is unkown", %{rel: rel} do
      rel = %{rel | deployment_state: :huh}
      assert {:noreply, rel} = handle_info(:next, rel)
    end

  end

  describe "reset" do
    test "returns the state to :initial", %{rel: rel} do
      rel = %{rel | deployment_state: :huh}
      assert {:noreply, %{deployment_state: :initial}} = handle_info(:reset, rel)
      assert_receive :next, @message_delay
    end
  end
end
