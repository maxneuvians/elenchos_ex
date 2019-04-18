defmodule ElenchosEx.RepositoryTest do
  use ExUnit.Case, async: false

  import ElenchosEx.Repository

  @code_dir Application.get_env(:elenchos_ex, :code_dir, "/tmp")

  describe "checks out a repository at a certain sha" do
    test "returns {:ok, :checked_out} if the repository can be checked out" do
      sha = "f40697d53cbd67d74718dc8a58aa6b66692034f3"
      assert {:ok, :checked_out} = checkout(%{full_name: "cds-snc/dns", sha: sha})
      cleanup(%{sha: sha})
    end

    test "returns {:error, error, code} if the repository can not be checked out" do
      sha = "abcd"
      assert {:error, "128: " <> _rest} = checkout(%{full_name: "cds-snc/abcd", sha: sha})
      cleanup(%{sha: sha})
    end
  end

  describe "cleanup exiting code" do
    test "returns {:ok, :cleaned_up} if the repository is deleted" do
      sha = "f40697d53cbd67d74718dc8a58aa6b66692034f3"
      checkout(%{full_name: "cds-snc/dns", sha: sha})
      assert {:ok, cleaned_up} = cleanup(%{sha: sha})
    end
  end

  describe "validates elenchos config" do
    test "returns {:error, 'File does not exist'} if the file does not exist" do
      sha = "abcd"
      assert {:error, "File does not exist"} = validate_elenchos_config(%{sha: sha})
    end

    test "returns {:error, 'Could not decode JSON'} if it can not decode JSON" do
      sha = "f40697d53cbd67d74718dc8a58aa6b66692034f3"
      checkout(%{full_name: "cds-snc/dns", sha: sha})
      File.write!(@code_dir <> "/" <> sha <> "/elenchos.json", "")
      assert {:error, "Could not decode JSON"} = validate_elenchos_config(%{sha: sha})
      cleanup(%{sha: sha})
    end

    test "returns {:error, 'Config is missing overlay key'} if overlay key is missing" do
      sha = "f40697d53cbd67d74718dc8a58aa6b66692034f3"
      checkout(%{full_name: "cds-snc/dns", sha: sha})
      File.write!(@code_dir <> "/" <> sha <> "/elenchos.json", "{\"dockerfiles\":{}}")
      assert {:error, "Config is missing overlay key"} = validate_elenchos_config(%{sha: sha})
      cleanup(%{sha: sha})
    end

    test "returns {:error, 'Config is missing overlay key'} if dockerfiles key is missing" do
      sha = "f40697d53cbd67d74718dc8a58aa6b66692034f3"
      checkout(%{full_name: "cds-snc/dns", sha: sha})
      File.write!(@code_dir <> "/" <> sha <> "/elenchos.json", "{\"overlay\":{}}")
      assert {:error, "Config is missing dockerfiles key"} = validate_elenchos_config(%{sha: sha})
      cleanup(%{sha: sha})
    end

    test "returns {:error, 'Config is missing dockerfiles and overlay keys'} if both keys are missing" do
      sha = "f40697d53cbd67d74718dc8a58aa6b66692034f3"
      checkout(%{full_name: "cds-snc/dns", sha: sha})
      File.write!(@code_dir <> "/" <> sha <> "/elenchos.json", "{}")
      assert {:error, "Config is missing dockerfiles and overlay keys"} = validate_elenchos_config(%{sha: sha})
      cleanup(%{sha: sha})
    end

    test "returns true if they key is valid" do
      sha = "f40697d53cbd67d74718dc8a58aa6b66692034f3"
      checkout(%{full_name: "cds-snc/dns", sha: sha})
      File.write!(@code_dir <> "/" <> sha <> "/elenchos.json", "{\"dockerfiles\":{}, \"overlay\":{}}")
      assert true = validate_elenchos_config(%{sha: sha})
      cleanup(%{sha: sha})
    end
  end
end
