defmodule ElenchosEx.ReleaseTest do
  use ExUnit.Case, async: true

  import ElenchosEx.Release
  alias ElenchosEx.Release.Model

  describe "load" do
    test "returns a release if it is found" do
      release = %Model{ref: "abcd", sha: "efgh"}
      save(release)
      assert {:ok, ^release} = load(release.ref)
      :ets.delete(:releases, release.ref)
    end

    test "returns an error if it is not found found" do
      release = %Model{ref: "abcd", sha: "efgh"}
      assert {:error, "Could not find release"} = load(release.ref)
    end
  end

  describe "save" do
    test "returns a release if it is able to save it" do
      release = %Model{ref: "abcd", sha: "efgh"}
      assert save(release)
      :ets.delete(:releases, release.ref)
    end
  end

end
